resource "aws_s3_bucket" "this" {
  count  = var.enabled ? 1 : 0
  bucket = local.bucket_name

  force_destroy = var.force_destroy

  tags = local.common_tags
}

# Ownership controls
resource "aws_s3_bucket_ownership_controls" "this" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = var.block_public
  block_public_policy     = var.block_public
  ignore_public_acls      = var.block_public
  restrict_public_buckets = var.block_public
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

# Default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

