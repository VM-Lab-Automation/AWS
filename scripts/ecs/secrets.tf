resource "aws_secretsmanager_secret" "cr_secret" {
  name                = "cr_secret_17"
}

resource "aws_secretsmanager_secret_version" "cr_secret_version" {
  secret_id     = aws_secretsmanager_secret.cr_secret.id
  secret_string = jsonencode({
    "username" : var.container_registry_username,
    "password" : var.container_registry_password
  })
}
