resource "aws_ecs_task_definition" "backend" {
  family = "backend_service"
  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "vmautomation.azurecr.io/vmautomationbackend:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      environment = [
        {
          name = "DATABASE_CONNECTION_STRING"
          value = var.db_connection_string
        },
        {
          name = "JWT_SECRET"
          value = "please_create_random_password_here"
        }
      ]
      repositoryCredentials = {
        credentialsParameter = aws_secretsmanager_secret.cr_secret.arn
      }
    }
  ])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_task_definition" "frontend" {
  family = "frontend_service"
  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "vmautomation.azurecr.io/vmautomationfrontend:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      repositoryCredentials = {
        credentialsParameter = aws_secretsmanager_secret.cr_secret.arn
      }
    }
  ])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}


resource "aws_ecs_cluster" "vmautomation_cluster" {
  name = "vmautomation_cluster"
}

resource "aws_ecs_service" "backend" {
  name            = "backend"
  cluster         = aws_ecs_cluster.vmautomation_cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.vmautomation_cluster.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
}
