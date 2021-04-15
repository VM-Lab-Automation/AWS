resource "aws_ecs_task_definition" "backend_service_definition" {
  family = "backend_service"
  container_definitions = jsonencode([
    {
      name      = "backend"
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

resource "aws_ecs_cluster" "backend_cluster" {
  name = "backend_cluster"
}

resource "aws_ecs_service" "backend" {
  name            = "backend"
  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.backend_service_definition.arn
  desired_count   = 1
}
