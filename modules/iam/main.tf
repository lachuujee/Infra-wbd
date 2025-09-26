# Trust policy (who can assume this role)
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = var.assume_services
    }
  }
}

# IAM Role
resource "aws_iam_role" "this" {
  count              = var.enabled ? 1 : 0
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  path               = var.path
  tags               = local.common_tags
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each  = var.enabled ? toset(var.managed_policy_arns) : toset([])
  role      = aws_iam_role.this[0].name
  policy_arn = each.value
}

# Instance profile (useful for EC2)
resource "aws_iam_instance_profile" "this" {
  count = var.enabled ? 1 : 0
  name  = "${var.role_name}-profile"
  role  = aws_iam_role.this[0].name
  path  = var.path
  tags  = local.common_tags
}

