output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "subnet_ids" {
  value = [aws_subnet.primary.id, aws_subnet.secondary.id]
}