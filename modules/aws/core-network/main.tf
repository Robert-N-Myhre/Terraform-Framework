# ===========================================================================
# AWS Core Network Fabric — VPC, subnets, routing, NAT, flow logs
#
# Independently invocable: this module sources no other module in this
# framework and requires no pre-existing framework-managed resources.
# ===========================================================================

locals {
  # Naming convention: {prefix}-{cloud}-{environment}-{resource-type}-{suffix}
  # (see governance/naming/README.md — pattern is self-contained by design)
  name_base = "${var.prefix}-aws-${var.environment}"

  # Tagging convention (see governance/tagging/README.md — self-contained copy)
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "modules/aws/core-network"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)

  public_subnets  = { for k, v in var.subnets : k => v if v.tier == "public" }
  private_subnets = { for k, v in var.subnets : k => v if v.tier == "private" }

  # NAT placement: one gateway per AZ that hosts a public subnet ("per_az"),
  # or a single gateway in the first public subnet ("single").
  nat_azs = var.enable_nat_gateway ? (
    var.nat_gateway_strategy == "per_az"
    ? toset([for s in local.public_subnets : s.availability_zone])
    : toset(length(local.public_subnets) > 0 ? [values(local.public_subnets)[0].availability_zone] : [])
  ) : toset([])

  # First public subnet key per AZ — NAT gateways land here.
  public_subnet_by_az = {
    for az in local.nat_azs :
    az => [for k, s in local.public_subnets : k if s.availability_zone == az][0]
  }
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-vpc-${var.name_suffix}"
  })
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.tier == "public" ? each.value.map_public_ip_on_launch : false

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-subnet-${each.key}"
    tier = each.value.tier
  })
}

# ---------------------------------------------------------------------------
# Internet gateway + public routing
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  count = var.enable_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-igw-${var.name_suffix}"
  })
}

resource "aws_route_table" "public" {
  count = length(local.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-rt-public-${var.name_suffix}"
  })
}

resource "aws_route" "public_internet" {
  count = var.enable_internet_gateway && length(local.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# ---------------------------------------------------------------------------
# NAT gateways + private routing
#
# One private route table per subnet keeps route ownership unambiguous and
# lets consumers (e.g., a transit module invoked separately) inject routes
# per subnet without contention.
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  for_each = local.public_subnet_by_az

  domain = "vpc"

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-eip-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = local.public_subnet_by_az

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.this[each.value].id

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-rt-private-${each.key}"
  })
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? local.private_subnets : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  # Prefer the NAT gateway in the same AZ; fall back to the first one.
  nat_gateway_id = try(
    aws_nat_gateway.this[each.value.availability_zone].id,
    values(aws_nat_gateway.this)[0].id
  )
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# ---------------------------------------------------------------------------
# Flow logs (CloudWatch destination, module-managed log group and role)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/vpc/${local.name_base}-vpc-${var.name_suffix}/flow-logs"
  retention_in_days = var.flow_log_retention_days

  tags = local.all_tags
}

data "aws_iam_policy_document" "flow_logs_assume" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs_write" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_logs[0].arn}:*"]
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name               = "${local.name_base}-role-flowlogs-${var.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume[0].json

  tags = local.all_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name   = "${local.name_base}-policy-flowlogs-${var.name_suffix}"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_write[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = var.flow_log_traffic_type
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(local.all_tags, {
    Name = "${local.name_base}-flowlog-${var.name_suffix}"
  })
}
