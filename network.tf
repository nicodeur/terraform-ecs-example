# Créer un groupe de sécurité personnalisé qui autorise les ports 80 et 443
resource "aws_security_group" "sg_your_website" {
  name_prefix = "${var.application_name}-security-group"

  vpc_id = "vpc-07c7013ccbbb1ebfc" # Remplacez par l'ID du VPC approprié

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Vous pouvez également spécifier des plages IP spécifiques ici
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Vous pouvez également spécifier des plages IP spécifiques ici
  }

  ingress {
    description = "Allow website traffic"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Vous pouvez également spécifier des plages IP spécifiques ici
  }

  # Règle d'égress pour autoriser le trafic sortant vers les services AWS, y compris ECR
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic to AWS services"
  }
}

# Créer un équilibreur de charge réseau (ALB)
resource "aws_lb" "your-website-alb" {
  name               = "${var.application_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-05e286b5dd5506c21", "subnet-0c1716bb2c0062884"] # Remplacez par les sous-réseaux publics appropriés

  security_groups = [aws_security_group.sg_your_website.id]
}

# Créer un groupe de cibles pour l'équilibreur de charge réseau
resource "aws_lb_target_group" "your-website-target-group" {
  name     = "${var.application_name}-target-group"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = "vpc-07c7013ccbbb1ebfc" # Remplacez par l'ID du VPC approprié
  target_type = "ip"
}

# Créer un écouteur pour diriger le trafic entrant vers le groupe de cibles
resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.your-website-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # Rediriger avec le code de statut 301 (permanent)
    }
  }
}

resource "aws_lb_listener" "https-listener" {
  load_balancer_arn = aws_lb.your-website-alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    target_group_arn = aws_lb_target_group.your-website-target-group.arn
    type             = "forward"
  }

  # Associer le certificat ACM au listener HTTPS
  certificate_arn = aws_acm_certificate.your-website-acm-certificate.arn
}

# Créer un enregistrement DNS de type "A" dans Route 53 pour l'URL de l'application
resource "aws_route53_record" "your-website" {
  zone_id = var.domain_name_zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.your-website-alb.dns_name] # Utiliser l'adresse IP de l'équilibreur de charge réseau comme enregistrement DNS
}

/////// certificate https //////////
# Créer le certificat ACM pour votre domaine
# Il y a une étapes manuel, il faut aller sur la console de ACM, et creer l'enregistrement qui permet de valider
# que le nom de domaine est bien le votre (nouvelle entrée CNAME dans le DNS)
# une fois le cerificat validé, relancer le terraform
resource "aws_acm_certificate" "your-website-acm-certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}