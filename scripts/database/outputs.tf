output "db_password" {
  value = aws_db_instance.database.password
}

output "db_connection_string" {
  value = "postgresql://${aws_db_instance.database.username}:${aws_db_instance.database.password}@${aws_db_instance.database.address}:${aws_db_instance.database.port}/${aws_db_instance.database.name}"
}