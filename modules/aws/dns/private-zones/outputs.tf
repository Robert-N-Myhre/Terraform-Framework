# Output contract for the dns domain (see docs/adr/002):
# zone_ids, zone_names, record_ids

output "zone_ids" {
  description = "Map of logical zone name to Route 53 hosted zone ID."
  value       = { for k, z in aws_route53_zone.this : k => z.zone_id }
}

output "zone_names" {
  description = "Map of logical zone name to DNS domain name."
  value       = { for k, z in aws_route53_zone.this : k => z.name }
}

output "zone_arns" {
  description = "Map of logical zone name to hosted zone ARN."
  value       = { for k, z in aws_route53_zone.this : k => z.arn }
}

output "record_ids" {
  description = "Map of '<zone-key>/<record-key>' to record FQDN."
  value       = { for k, r in aws_route53_record.this : k => r.fqdn }
}
