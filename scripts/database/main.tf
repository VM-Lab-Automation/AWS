resource "random_password" "database_password" {
  length  = 16
  special = false

  keepers = {
    master_password_seed = var.password_seed
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "database" {
  allocated_storage   = var.allocated_size
  engine              = var.engine_type
  instance_class      = var.instance_class
  name                = var.db_name
  username            = var.username
  password            = random_password.database_password.result
  publicly_accessible = true
  skip_final_snapshot = true

  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
}