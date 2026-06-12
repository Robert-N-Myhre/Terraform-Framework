# Output contract for the core-network domain (see docs/adr/002):
# network_id, network_cidr, subnet_ids, route_table_ids, nat_ids, flow_log_id

output "network_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "network_cidr" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "network_arn" {
  description = "ARN of the created VPC."
  value       = aws_vpc.this.arn
}

output "subnet_ids" {
  description = "Map of logical subnet name to subnet ID."
  value       = { for k, s in aws_subnet.this : k => s.id }
}

output "subnet_cidrs" {
  description = "Map of logical subnet name to subnet CIDR block."
  value       = { for k, s in aws_subnet.this : k => s.cidr_block }
}

output "route_table_ids" {
  description = "Map of route table IDs: key 'public' for the shared public table (if any), plus one entry per private subnet keyed by logical subnet name."
  value = merge(
    length(aws_route_table.public) > 0 ? { public = aws_route_table.public[0].id } : {},
    { for k, rt in aws_route_table.private : k => rt.id }
  )
}

output "internet_gateway_id" {
  description = "ID of the internet gateway, or null when enable_internet_gateway = false."
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "nat_ids" {
  description = "Map of availability zone to NAT gateway ID. Empty when enable_nat_gateway = false."
  value       = { for az, ngw in aws_nat_gateway.this : az => ngw.id }
}

output "nat_public_ips" {
  description = "Map of availability zone to NAT gateway public IP. Empty when enable_nat_gateway = false."
  value       = { for az, eip in aws_eip.nat : az => eip.public_ip }
}

output "flow_log_id" {
  description = "ID of the VPC flow log, or null when enable_flow_logs = false."
  value       = try(aws_flow_log.this[0].id, null)
}
