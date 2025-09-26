output "vpc_id" {
  value       = var.enabled ? aws_vpc.this[0].id : null
  description = "VPC ID"
}

output "vpc_cidr_block" {
  value       = var.enabled ? aws_vpc.this[0].cidr_block : null
  description = "VPC CIDR"
}

output "public_subnet_ids" {
  value       = var.enabled ? [for k, s in aws_subnet.public : s.id] : []
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = [for k, s in aws_subnet.private : s.id]
  description = "Private subnet IDs"
}

output "private_subnet_ids_by_role" {
  value = {
    for k, s in aws_subnet.private :
    k => s.id
  }
  description = "Map of private subnets by role key (e.g., app-a, api-b, db-a)"
}
