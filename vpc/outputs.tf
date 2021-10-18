output "vpc_id" {
  value       = aws_vpc.main.id
  description = "the id of the vpc"
}

output "vpc_cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "cidr prefix of vpc"
}

output "route_table_ids" {
  value = tolist(
    [aws_route_table.prod.id,
      aws_route_table.staging.id,
      aws_route_table.dev.id,
    aws_route_table.public.id]
  )

  description = "Route tables for vpc subnets"
}
