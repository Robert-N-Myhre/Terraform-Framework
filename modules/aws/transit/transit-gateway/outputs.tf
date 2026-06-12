# Output contract for the transit domain (see docs/adr/002):
# hub_id, attachment_ids, route_table_ids

output "hub_id" {
  description = "ID of the transit gateway."
  value       = aws_ec2_transit_gateway.this.id
}

output "hub_arn" {
  description = "ARN of the transit gateway."
  value       = aws_ec2_transit_gateway.this.arn
}

output "attachment_ids" {
  description = "Map of logical attachment name to TGW VPC attachment ID."
  value       = { for k, a in aws_ec2_transit_gateway_vpc_attachment.this : k => a.id }
}

output "route_table_ids" {
  description = "Map of logical route table name to TGW route table ID, plus 'default' for the TGW default association route table."
  value = merge(
    { for k, rt in aws_ec2_transit_gateway_route_table.this : k => rt.id },
    { default = aws_ec2_transit_gateway.this.association_default_route_table_id }
  )
}

output "static_route_ids" {
  description = "Map of logical static route name to TGW route ID."
  value       = { for k, r in aws_ec2_transit_gateway_route.this : k => r.id }
}
