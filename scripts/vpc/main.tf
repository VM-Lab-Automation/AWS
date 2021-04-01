resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    App = "${var.project}-${var.env}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "primary" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    App = "${var.project}-${var.env}"
    Type = "primary"
  }
}

resource "aws_subnet" "secondary" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    App = "${var.project}-${var.env}"
    Type = "secondary"
  }
}

resource "aws_route_table_association" "rta_primary"{
  subnet_id = aws_subnet.primary.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "rta_secondary"{
  subnet_id = aws_subnet.secondary.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "db" {
  name = "vlab-db-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = "5432"
    to_port     = "5432"
    protocol    = "tcp"
    description = "PostgreSQL port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}