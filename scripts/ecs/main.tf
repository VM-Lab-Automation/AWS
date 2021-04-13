resource "aws_secretsmanager_secret" "cr_secret" {
  name                = "cr_secret_3"
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
          Service = ["ec2.amazonaws.com","ecs-tasks.amazonaws.com"]
        }
      },
    ]
  })
}

resource "aws_iam_policy" "cr_policy_secretsmanager" {
  name = "password-policy-secretsmanager"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect = "Allow",
        Resource = [
          aws_secretsmanager_secret.cr_secret.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role       = aws_iam_role.ecs_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "secrets-attach" {
  role       = aws_iam_role.ecs_task_execution_role.id
  policy_arn = aws_iam_policy.cr_policy_secretsmanager.arn
}

resource "aws_iam_instance_profile" "ecs_execution_profile" {
  name = "ecs_execution_profile"
  role = aws_iam_role.ecs_task_execution_role.name
}

# data "aws_ami" "ecs_optimized" {
#   owners           = ["self"]
#   filter {
#     name   = "name"
#     values = ["amzn-ami-2017.09.l-amazon-ecs-optimized"]
#   }
# }

# data "template_file" "user_data" {
#   template = "${file("ecs/user_data.yaml")}"

#   vars {
#     ecs_cluster = aws.ecs_cluster.backend_cluster.name
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

resource "aws_launch_configuration" "ecs-launch-configuration" {
  name = "ecs-launch-configuration"
  image_id = "ami-aff65ad2"#data.aws_ami.ecs_optimized.id
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_execution_profile.id
  
  lifecycle {
    create_before_destroy = true
  }
  associate_public_ip_address = "false"
  # key_name = "testone"
  user_data            = templatefile("${path.module}/user-data.sh", { cluster_name = aws_ecs_cluster.backend_cluster.name })

}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name = "ecs-autoscaling-group"
  max_size = "1"
  min_size = "1"
  desired_capacity = "1"
  # vpc_zone_identifier = ["subnet-41395d29"]
  vpc_zone_identifier = var.subnet_ids
  launch_configuration = aws_launch_configuration.ecs-launch-configuration.name
  health_check_type = "ELB"
  # tag {
  # }
}
