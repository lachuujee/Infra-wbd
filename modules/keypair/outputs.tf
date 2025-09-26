output "key_name" {
  description = "KeyPair name to use in EC2"
  value       = local.key_name
}

output "key_pair_id" {
  description = "AWS KeyPair ID (same as name in most regions)"
  value       = aws_key_pair.this.id
}

output "private_key_secret_arn" {
  description = "Secrets Manager ARN where the private key PEM is stored"
  value       = aws_secretsmanager_secret.pk.arn
}
