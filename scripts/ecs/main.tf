resource "aws_ecs_task_definition" "backend" {
  family = "backend_service"
  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "vmautomation.azurecr.io/vmautomationbackend:latest"
      cpu       = 1
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

resource "aws_ecs_task_definition" "worker" {
  family = "worker_service"

        # when available in ami
        # {
        #   containerPath = "/dev/vboxdrv"
        #   sourceVolume = "/dev/vboxdrv"
        # }
  container_definitions = jsonencode([
    {
      name        = "worker"
      image       = "vmautomation.azurecr.io/vmautomationworker:latest"
      cpu         = 2
      memory      = 2048
      essential   = true
      privileged  = true
      command     = ["./start_release.sh", "8000"]
      
      mountPoints = [
        {
          containerPath = "/var/lib/docker"
          sourceVolume = "dind1"
        },
        {
          containerPath = "/labs"
          sourceVolume = "labs1"
        },
      ]
      environment = [
        {
          name = "WORKER_ID"
          value = "WORDER_AWS1"
        },
        {
          name = "MAIN_SERVER_URL"
          value = "http://${aws_lb.vmautomation.dns_name}/api"
        },
        {
          name = "LABS_PATH"
          value = "/labs"
        },
        {
          name = "WORKER_HOST"
          value = "test"
        },
        {
          name = "WORKER_PORT"
          value = "8000"
        }
      ]
      repositoryCredentials = {
        credentialsParameter = aws_secretsmanager_secret.cr_secret.arn
      }
    }
  ])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name      = "dind1"
    host_path = "/vmautomation/dind1"
  }
  volume {
    name      = "labs1"
    host_path = "/vmautomation/labs1"
  }

  network_mode = "host"
}

resource "aws_ecs_task_definition" "frontend" {
  family = "frontend_service"
  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "vmautomation.azurecr.io/vmautomationfrontend:latest"
      cpu       = 1
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

resource "aws_ecs_service" "worker" {
  name            = "worker"
  cluster         = aws_ecs_cluster.vmautomation_cluster.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
}
