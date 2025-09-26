# 1) Generate private/public key (no .pem written to disk)
resource "tls_private_key" "this" {
  count     = var.enabled ? 1 : 0
  algorithm = var.algorithm
  rsa_bits  = var.algorithm == "RSA" ? var.rsa_bits : null
}

# 2) Register public key in EC2
resource "aws_key_pair" "this" {
  count      = var.enabled ? 1 : 0
  key_name   = local.key_name
  public_key = tls_private_key.this[0].public_key_openssh
  tags       = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

# 3) Secrets Manager secret (name EXACTLY equals the keypair name)
resource "aws_secretsmanager_secret" "pk" {
  count                   = var.enabled ? 1 : 0
  name                    = local.key_name              # e.g., SBX_INTAKE_ID_001-keypair
  recovery_window_in_days = 30
  tags                    = local.common_tags
}

# 4) Store PEM string in the secret
resource "aws_secretsmanager_secret_version" "pkv" {
  count         = var.enabled ? 1 : 0
  secret_id     = aws_secretsmanager_secret.pk[0].id
  secret_string = tls_private_key.this[0].private_key_pem
}
