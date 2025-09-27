output "instance_ids" {
  description = "EC2 instance IDs"
  value       = [for i in aws_instance.this : i.id]
}

output "instance_private_ips" {
  description = "Private IPs of instances"
  value       = [for i in aws_instance.this : i.private_ip]
}

output "security_group_id" {
  description = "Security group protecting these instances"
  value       = var.enabled ? aws_security_group.app[0].id : null
}
