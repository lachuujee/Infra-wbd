output "security_group_id" {
  description = "EC2 SG ID"
  value       = length(aws_security_group.app_sg) > 0 ? aws_security_group.app_sg[0].id : null
}

output "instance_ids" {
  description = "Launched instance IDs"
  value       = [for i in aws_instance.app : i.id]
}

output "private_ips" {
  description = "Launched instance private IPs"
  value       = [for i in aws_instance.app : i.private_ip]
}

output "effective_ami" {
  description = "AMI actually used for launch"
  value       = local.effective_ami
  sensitive   = true  # <-- REQUIRED to satisfy Terraform's sensitive-output rule
}

output "key_name_used" {
  description = "KeyPair name used (if any)"
  value       = local.key_name
}

output "iam_profile_used" {
  description = "IAM instance profile used (if any)"
  value       = local.iam_instance_profile
}
