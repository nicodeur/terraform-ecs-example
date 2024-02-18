# Créer un repository ECR pour stocker les images Docker (optionnel si vous utilisez un autre registry d'images)
resource "aws_ecr_repository" "your-website" {
  name = var.ecr_repository_name
}

# Créer un rôle IAM pour l'exécution des tâches ECS avec les stratégies nécessaires pour accéder à ECR
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs-task-execution-policy"
  description = "Policy to allow CloudWatch logs access for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource  = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/ecs/${var.application_name}:*"
      }
    ]
  })
}

# Attacher la stratégie AWS pour accéder à ECR au rôle IAM
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Stratégie pour accéder en lecture seule à ECR
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment2" {
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
  role       = aws_iam_role.ecs_task_execution_role.name
}