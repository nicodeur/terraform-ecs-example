# Créer un groupe de journaux CloudWatch pour votre application ECS
resource "aws_cloudwatch_log_group" "your-website" {
  name = "/ecs/your-website" # Remplacez par le nom de votre application ECS
}

# Créer un flux de journaux associé au groupe de journaux CloudWatch
resource "aws_cloudwatch_log_stream" "your-website" {
  name           = "ecs-your-website" # Remplacez par le nom de votre flux de journaux
  log_group_name = aws_cloudwatch_log_group.your-website.name
}

# Créer une définition de tâche ECS (à retirer car nous utilisons un service ECS)
resource "aws_ecs_task_definition" "your-website" {
  family                   = var.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"

  cpu       = 1024
  memory    = 2048

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions    = jsonencode([{
    name      = "${var.application_name}--container"
    image     = aws_ecr_repository.your-website.repository_url
    cpu       = 1024
    memory    = 2048
    portMappings = [{
      containerPort = 4000
      hostPort      = 4000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"  = aws_cloudwatch_log_group.your-website.name
        "awslogs-region" = "eu-west-1"
        "awslogs-stream-prefix" = "ecs-${var.application_name}"
      }
    }
  }])
}

# Créer un cluster ECS
resource "aws_ecs_cluster" "your-website" {
  name = var.cluster_name
}

# Créer un service ECS
resource "aws_ecs_service" "your-website" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.your-website.arn # Remplacez par l'ARN de la définition de tâche que vous avez créée manuellement ou avec un autre moyen

  desired_count   = 1 # Spécifiez le nombre d'instances de tâches à maintenir en cours d'exécution

  launch_type     = "FARGATE"

  # Configurer le déploiement
  deployment_controller {
    type = "ECS"
  }

  # Configurer les paramètres du service
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Configurer le service à utiliser un load balancer (si vous en avez un)
  load_balancer {
    target_group_arn = aws_lb_listener.https-listener.default_action[0].target_group_arn
    # target_group_arn = aws_lb_target_group.your-website.arn
    container_name   = "${var.application_name}--container"
    container_port   = 4000
  }

  # Configurer le rôle IAM ARN pour les autorisations des instances EC2 du service (si vous utilisez EC2 launch type)
  # execution_role_arn = aws_iam_role.ecs_execution_role.arn

  # Configurer les options de réseau pour le service
  network_configuration {
    assign_public_ip = true
    subnets            = ["subnet-05e286b5dd5506c21", "subnet-0c1716bb2c0062884"] # Remplacez par les sous-réseaux publics appropriés
    security_groups    = [aws_security_group.sg_your_website.id] # Utiliser le groupe de sécurité
  }

  # Définir les dépendances pour la création du service
  depends_on = [aws_ecs_cluster.your-website, aws_lb_target_group.your-website-target-group]

  # Configurer les paramètres de déploiement du service (facultatif)
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}