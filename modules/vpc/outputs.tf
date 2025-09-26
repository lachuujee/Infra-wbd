output "vpc_id" {
  description = "VPC ID"
  value       = try(aws_vpc.this[0].id, null)
}

output "vpc_cidr_block" {
  description = "VPC CIDR"
  value       = try(aws_vpc.this[0].cidr_block, null)
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [for k, s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs (deterministic order by key)"
  value       = [for k, s in aws_subnet.private : s.id]
}

output "private_subnet_ids_by_role" {
  description = "Map of private subnets by role key (e.g., app-a, api-b, db-a)"
  value       = { for k, s in aws_subnet.private : k => s.id }
}
