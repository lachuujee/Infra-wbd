############################################
# AZs (safe, null-proof, one-line ternary)
############################################
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # if azs is null -> [], else the provided list
  _azs_input   = coalesce(var.azs, [])
  _azs_default = slice(data.aws_availability_zones.available.names, 0, 2)
  azs_effective = length(local._azs_input) >= 2 ? local._azs_input : local._azs_default

  az0 = local.azs_effective[0]
  az1 = local.azs_effective[1]
}

############################################
# Prefer CIDR unless you explicitly null it
############################################
locals {
  cidr_is_set = var.cidr_block != null && trim(var.cidr_block) != ""
  use_ipam    = !local.cidr_is_set
}

resource "aws_vpc" "this" {
  count = var.enabled ? 1 : 0

  ipv4_ipam_pool_id   = local.use_ipam ? var.ipam_pool_id       : null
  ipv4_netmask_length = local.use_ipam ? var.vpc_netmask_length : null
  cidr_block          = local.use_ipam ? null                   : var.cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.common_tags

  lifecycle {
    precondition {
      condition     = local.use_ipam ? (var.ipam_pool_id != null && trim(var.ipam_pool_id) != "") : (local.cidr_is_set)
      error_message = "Provide either a valid cidr_block OR (ipam_pool_id + vpc_netmask_length)."
    }
  }
}

locals {
  vpc_id   = var.enabled ? aws_vpc.this[0].id : null
  vpc_cidr = var.enabled ? aws_vpc.this[0].cidr_block : null
}

############################################
# CIDR planning
############################################
locals {
  private_cidrs = var.enabled ? [
    cidrsubnet(local.vpc_cidr, 3, 0),
    cidrsubnet(local.vpc_cidr, 3, 1),
    cidrsubnet(local.vpc_cidr, 3, 2),
    cidrsubnet(local.vpc_cidr, 3, 3),
    cidrsubnet(local.vpc_cidr, 3, 4),
    cidrsubnet(local.vpc_cidr, 3, 5)
  ] : []

  public_parent = var.enabled ? cidrsubnet(local.vpc_cidr, 4, 15) : null
  public_cidrs  = var.enabled ? [
    cidrsubnet(local.public_parent, 4, 0),
    cidrsubnet(local.public_parent, 4, 1)
  ] : []

  private_def = var.enabled ? {
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
  count = var.enabled ? 1 : 0
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
  for_each      = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private_app" {
  count = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rtb-private-app", Service = "RouteTablePrivate" })
}

resource "aws_route_table" "private_api" {
  count = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rtb-private-api", Service = "RouteTablePrivate" })
}

resource "aws_route_table" "private_db" {
  count = var.enabled ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rtb-private-db", Service = "RouteTablePrivate" })
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
    Name    = "${local.name_prefix}-private-${each.value.role}-${substr(each.key, -1, 1)}"
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
# NACL, Flow Logs (unchanged from your version)
############################################
# ... keep your existing NACL and Flow Logs blocks ...
