resource "aws_secretsmanager_secret" "cr_secret" {
  name                = "cr_secret"
}

resource "aws_secretsmanager_secret_version" "cr_secret_version" {
  secret_id     = aws_secretsmanager_secret.cr_secret.id
  secret_string = jsonencode({
    "username" : var.container_registry_username,
    "password" : var.container_registry_password
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_exectution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "cr_policy_secretsmanager" {
  name = "password-policy-secretsmanager"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_secretsmanager_secret.cr_secret.arn}"
        ]
      }
    ]
  })
}

# resource "aws_launch_configuration" "ecs-launch-configuration" {
#   name = "ecs-launch-configuration"
#   image_id = "ami-aff65ad2"
#   instance_type = "t2.micro"
#   iam_instance_profile = "${aws_iam_instance_profile.ecs-instance-profile.id}"
#   root_block_device {
#     volume_type = "standard"
#     volume_size = 100
#     delete_on_termination = true
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
#   associate_public_ip_address = "false"
#   key_name = "testone"
#   #
#   # register the cluster name with ecs-agent which will in turn coord
#   # with the AWS api about the cluster
#   #
#   user_data = <> /etc/ecs/ecs.config
# EOF
# }
# #
# # need an ASG so we can easily add more ecs host nodes as necessary
# #
# resource "aws_autoscaling_group" "ecs-autoscaling-group" {
#   name = "ecs-autoscaling-group"
#   max_size = "2"
#   min_size = "1"
#   desired_capacity = "1"
#   # vpc_zone_identifier = ["subnet-41395d29"]
#   vpc_zone_identifier = ["${module.new-vpc.private_subnets}"]
#   launch_configuration = "${aws_launch_configuration.ecs-launch-configuration.name}"
#   health_check_type = "ELB"
#   tag {
#     key = "Name"
#     value = "ECS-myecscluster"
#     propagate_at_launch = true
#   }
# }


resource "aws_ecs_task_definition" "backend_service_definition" {
  family = "backend_service"
  container_definitions = jsonencode([
    {
      name      = "backend"
      # image     = "vmautomation.azurecr.io/vmautomationbackend:latest"
      image     = "nginx:alpine" 
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      # repositoryCredentials = {
      #   credentialsParameter = aws_secretsmanager_secret.cr_secret.arn
      # }
    }
  ])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_cluster" "backend_cluster" {
  name = "backend_cluster"
}

resource "aws_ecs_service" "backend" {
  name            = "backend"
  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.backend_service_definition.arn
  desired_count   = 1
}