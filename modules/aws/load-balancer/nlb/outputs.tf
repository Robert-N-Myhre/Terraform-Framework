# Output contract for the load-balancer domain (see docs/adr/002):
# lb_id, lb_dns_name/lb_address, listener_ids, backend_ids

output "lb_id" {
  description = "ARN of the network load balancer."
  value       = aws_lb.this.arn
}

output "lb_dns_name" {
  description = "DNS name of the NLB."
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Route 53 hosted zone ID of the NLB (for alias records)."
  value       = aws_lb.this.zone_id
}

output "listener_ids" {
  description = "Map of logical listener name to listener ARN."
  value       = { for k, l in aws_lb_listener.this : k => l.arn }
}

output "backend_ids" {
  description = "Map of logical target group name to target group ARN. Register targets against these in the consumer root module."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}
