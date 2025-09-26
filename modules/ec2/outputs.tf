output "instance_id" {
  value       = var.enabled ? aws_instance.this[0].id : null
  description = "EC2 instance ID"
}

output "private_ip" {
  value       = var.enabled ? aws_instance.this[0].private_ip : null
  description = "Private IP"
}

output "public_ip" {
  value       = var.enabled ? aws_instance.this[0].public_ip : null
  description = "Public IP"
}

output "ami_id_used" {
  value       = var.enabled ? aws_instance.this[0].ami : null
  description = "AMI actually used"
}
