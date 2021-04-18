resource "random_password" "jwt_password" {
  length = 24
  special = false

  keepers = {
    master_password_seed = var.password_seed
  }
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

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:dst == ${var.app_attr}"
  }
}

resource "aws_ecs_task_definition" "backend" {
  family = "backend_service"
  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "vmautomation.azurecr.io/vmautomationbackend:latest"
      cpu       = 1
      memory    = 768
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
          value = random_password.jwt_password.result
        }
      ]
      repositoryCredentials = {
        credentialsParameter = aws_secretsmanager_secret.cr_secret.arn
      }
    }
  ])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:dst == ${var.app_attr}"
  }
}

resource "aws_ecs_task_definition" "worker" {
  count = var.workers_count
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
      command     = ["./start_release.sh", "800${count.index}"]
      
      mountPoints = [
        {
          containerPath = "/var/lib/docker"
          sourceVolume = "dind${count.index}"
        },
        {
          containerPath = "/labs"
          sourceVolume = "labs${count.index}"
        },
      ]
      environment = [
        {
          name = "WORKER_ID"
          value = "WORKER_AWS${count.index}"
        },
        {
          name = "MAIN_SERVER_URL"
          value = "http://${aws_lb.vmautomation.dns_name}/api"
        },
        {
          name = "LABS_PATH"
          value = "/vmautomation/labs${count.index}/"
        },
        {
          name = "WORKER_HOST"
          value = aws_instance.ecs_worker[count.index].public_dns
        },
        {
          name = "WORKER_PORT"
          value = "800${count.index}"
        }
      ]
      repositoryCredentials = {
        credentialsParameter = aws_secretsmanager_secret.cr_secret.arn
      }
    }
  ])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name      = "dind${count.index}"
    host_path = "/vmautomation/dind${count.index}"
  }
  volume {
    name      = "labs${count.index}"
    host_path = "/vmautomation/labs${count.index}"
  }

  network_mode = "host"

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:dst == ${var.worker_attr}${count.index}"
  }
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
  count           = var.workers_count
  name            = "worker${count.index}"
  cluster         = aws_ecs_cluster.vmautomation_cluster.id
  task_definition = aws_ecs_task_definition.worker[count.index].arn
  desired_count   = 1
}
