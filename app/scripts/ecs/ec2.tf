resource "aws_security_group" "sg_cluster_app" {
  name   = "cluster-app-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    description = "HTTP Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    description = "HTTP Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    description = "SSH Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_cluster_worker" {
  name   = "cluster-worker-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = "8000"
    to_port     = "8000"
    protocol    = "tcp"
    description = "HTTP Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    description = "SSH Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "tls_private_key" "cluster_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "cluster_keypair" {
  key_name   = "cluster-key"
  public_key = tls_private_key.cluster_pk.public_key_openssh
}

resource "aws_launch_configuration" "ecs-launch-configuration" {
  name                 = "ecs-launch-configuration"
  image_id             = var.cluster_ami
  instance_type        = "t2.small"
  iam_instance_profile = aws_iam_instance_profile.ecs_execution_profile.id
  security_groups      = [aws_security_group.sg_cluster_app.id]
  key_name             = aws_key_pair.cluster_keypair.key_name



  lifecycle {
    create_before_destroy = true
  }
  associate_public_ip_address = "false"
  user_data = templatefile("${path.module}/user-data.sh", {
    cluster_name = aws_ecs_cluster.vmautomation_cluster.name,
    attributes   = jsonencode({ dst = var.app_attr })
  })
}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name                 = "ecs-autoscaling-group"
  max_size             = "2"
  min_size             = "1"
  desired_capacity     = "1"
  vpc_zone_identifier  = var.subnet_ids
  launch_configuration = aws_launch_configuration.ecs-launch-configuration.name
  health_check_type    = "ELB"
  # tag {
  # }
}

resource "aws_instance" "ecs_worker" {
  count                  = var.workers_count
  ami                    = var.cluster_ami
  instance_type          = "t2.medium"
  iam_instance_profile   = aws_iam_instance_profile.ecs_execution_profile.id
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.sg_cluster_worker.id]
  key_name               = aws_key_pair.cluster_keypair.key_name

  lifecycle {
    create_before_destroy = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    cluster_name = aws_ecs_cluster.vmautomation_cluster.name,
    attributes   = jsonencode({ dst = "${var.worker_attr}${count.index}" })
  })

  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }
}