output "role_name" {
  description = "IAM role name"
  value       = var.enabled ? aws_iam_role.this[0].name : null
}

output "role_arn" {
  description = "IAM role ARN"
  value       = var.enabled ? aws_iam_role.this[0].arn : null
}

output "instance_profile_name" {
  description = "Instance profile name"
  value       = var.enabled ? aws_iam_instance_profile.this[0].name : null
}

output "instance_profile_arn" {
  description = "Instance profile ARN"
  value       = var.enabled ? aws_iam_instance_profile.this[0].arn : null
}
