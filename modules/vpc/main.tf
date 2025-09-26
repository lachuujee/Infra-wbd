############################################
# Helper: AZs (auto-pick for current region)
############################################
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # null-safe: if var.azs is null use [], length([]) = 0
  azs_effective = length(coalesce(var.azs, [])) >= 2
    ? coalesce(var.azs, [])
    : slice(data.aws_availability_zones.available.names, 0, 2)
  az0 = local.azs_effective[0]
  az1 = local.azs_effective[1]
}

############################################
# Addressing: default to CIDR unless IPAM is explicitly provided
############################################
locals {
  # If cidr_block is null, fall back to 10.0.0.0/16 (safe default)
  cidr_effective = coalesce(var.cidr_block, "10.0.0.0/16")

  # Only use IPAM when you explicitly pass ipam_pool_id and you intentionally set cidr_block = null
  use_ipam = (var.cidr_block == null && var.ipam_pool_id != null)
}

resource "aws_vpc" "this" {
  count = var.enabled ? 1 : 0

  # CIDR (default) vs IPAM (only when both conditions are met)
  ipv4_ipam_pool_id   = local.use_ipam ? var.ipam_pool_id       : null
  ipv4_netmask_length = local.use_ipam ? var.vpc_netmask_length : null
  cidr_block          = local.use_ipam ? null                   : local.cidr_effective

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = local.use_ipam ? (var.ipam_pool_id != null) : (local.cidr_effective != null)
      error_message = "Provide either (cidr_block) OR (ipam_pool_id + vpc_netmask_length)."
    }
  }
}

locals {
  vpc_id   = var.enabled ? aws_vpc.this[0].id         : null
  vpc_cidr = var.enabled ? aws_vpc.this[0].cidr_block : null
}

############################################
# CIDR planning
# - 6 private /23 subnets (≈512 IPs)
# - 2 public  /28 subnets (≈16 IPs)
############################################
locals {
  private_cidrs  = var.enabled ? [
    cidrsubnet(local.vpc_cidr, 3, 0),
    cidrsubnet(local.vpc_cidr, 3, 1),
    cidrsubnet(local.vpc_cidr, 3, 2),
    cidrsubnet(local.vpc_cidr, 3, 3),
    cidrsubnet(local.vpc_cidr, 3, 4),
    cidrsubnet(local.vpc_cidr, 3, 5)
  ] : []

  public_parent  = var.enabled ? cidrsubnet(local.vpc_cidr, 4, 15) : null
  public_cidrs   = var.enabled ? [
    cidrsubnet(local.public_parent, 4, 0),
    cidrsubnet(local.public_parent, 4, 1)
  ] : []

  private_def    = var.enabled ? {
    "app-a" = { cidr = local.private_cidrs[0], az = local.az0, role = "app" }
    "app-b" = { cidr = local.private_cidrs[1], az = local.az1, role = "app" }
    "api-a" = { cidr = local.private_cidrs[2], az = local.az0, role = "api" }
    "api-b" = { cidr = local.private_cidrs[3], az = local.az1, role = "api" }
    "db-a"  = { cidr = local.private_cidrs[4], az = local.az0, role = "db"  }
    "db-b"  = { cidr = local.private_cidrs[5], az = local.az1, role = "db"  }
  } : {}
}

############################################
# Internet Gateway
############################################
resource "aws_internet_gateway" "igw" {
  count  = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-igw", Service = "InternetGateway" })
}

############################################
# Public subnets (2) — /28
############################################
resource "aws_subnet" "public" {
  for_each = var.enabled ? {
    "a" = { cidr = local.public_cidrs[0], az = local.az0 }
    "b" = { cidr = local.public_cidrs[1], az = local.az1 }
  } : {}

  vpc_id                  = local.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-public-${each.key}"
    Service = "SubnetPublic"
  })
}

############################################
# EIP + NAT (1 NAT in public-a)
############################################
resource "aws_eip" "nat" {
  count  = var.enabled ? 1 : 0
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-nat-eip", Service = "NATGateway" })
}

resource "aws_nat_gateway" "nat" {
  count         = var.enabled ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public["a"].id
  tags          = merge(local.common_tags, { Name = "${local.name_prefix}-nat", Service = "NATGateway" })
}

############################################
# Route tables
############################################
resource "aws_route_table" "public" {
  count  = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-rtb-public"
    Service = "RouteTablePublic"
  })
}

resource "aws_route" "public_default" {
  count                  = var.enabled ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private_app" {
  count  = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-rtb-private-app", Service = "RouteTablePrivate" })
}

resource "aws_route_table" "private_api" {
  count  = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-rtb-private-api", Service = "RouteTablePrivate" })
}

resource "aws_route_table" "private_db" {
  count  = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-rtb-private-db", Service = "RouteTablePrivate" })
}

resource "aws_route" "private_app_default" {
  count                  = var.enabled ? 1 : 0
  route_table_id         = aws_route_table.private_app[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route" "private_api_default" {
  count                  = var.enabled ? 1 : 0
  route_table_id         = aws_route_table.private_api[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route" "private_db_default" {
  count                  = var.enabled ? 1 : 0
  route_table_id         = aws_route_table.private_db[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

############################################
# Private subnets (6) — /23 + associations
############################################
resource "aws_subnet" "private" {
  for_each = local.private_def

  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-private-${each.value.role}-${split(each.key, "-")[1]}"
    Role    = upper(each.value.role)
    Service = "SubnetPrivate"
  })
}

locals {
  rtb_by_role = {
    app = aws_route_table.private_app[0].id
    api = aws_route_table.private_api[0].id
    db  = aws_route_table.private_db[0].id
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = local.private_def
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = local.rtb_by_role[each.value.role]
}

############################################
# NACL + Flow Logs
############################################
resource "aws_network_acl" "vpc_acl" {
  count  = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-nacl", Service = "NACL" })
}

resource "aws_network_acl_rule" "ingress_https" {
  count          = var.enabled ? 1 : 0
  network_acl_id = aws_network_acl.vpc_acl[0].id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "egress_all" {
  count          = var.enabled ? 1 : 0
  network_acl_id = aws_network_acl.vpc_acl[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_association" "assoc_public" {
  for_each       = aws_subnet.public
  network_acl_id = aws_network_acl.vpc_acl[0].id
  subnet_id      = each.value.id
}

resource "aws_network_acl_association" "assoc_private" {
  for_each       = aws_subnet.private
  network_acl_id = aws_network_acl.vpc_acl[0].id
  subnet_id      = each.value.id
}

data "aws_iam_policy_document" "flowlogs_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flowlogs_role" {
  count              = var.enabled ? 1 : 0
  name               = "${local.name_prefix}-vpc-flowlogs-role"
  assume_role_policy = data.aws_iam_policy_document.flowlogs_trust.json
  tags               = merge(local.common_tags, { Service = "FlowLogs" })
}

data "aws_iam_policy_document" "flowlogs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flowlogs_role_policy" {
  count  = var.enabled ? 1 : 0
  name   = "${local.name_prefix}-vpc-flowlogs-policy"
  role   = aws_iam_role.flowlogs_role[0].id
  policy = data.aws_iam_policy_document.flowlogs_policy.json
}

resource "aws_cloudwatch_log_group" "flowlogs" {
  count             = var.enabled ? 1 : 0
  name              = "/vpc/flowlogs/${local.name_prefix}"
  retention_in_days = var.flow_logs_retention_days
  tags              = merge(local.common_tags, { Service = "FlowLogs" })
}

resource "aws_flow_log" "vpc" {
  count                 = var.enabled ? 1 : 0
  vpc_id                = local.vpc_id
  log_destination_type  = "cloud-watch-logs"
  log_group_name        = aws_cloudwatch_log_group.flowlogs[0].name
  iam_role_arn          = aws_iam_role.flowlogs_role[0].arn
  traffic_type          = "ALL"
  tags                  = merge(local.common_tags, { Service = "FlowLogs" })
}
