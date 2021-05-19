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
          Service = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
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
