provider "aws" {
  region = "eu-west-1" # Remplacez par votre région AWS
}

# Définir les variables
variable "region" {
  type    = string
  default = "eu-west-1" # Nom de l'application par défaut
}

variable "account_id" {
  type    = string
  default = "your account_id" # Nom de l'application par défaut
}

variable "application_name" {
  type    = string
  default = "your-website" # Nom de l'application par défaut
}

variable "domain_name" {
  type    = string
  default = "your.domain.com" # Votre nom de domaine Route 53
}

variable "domain_name_zone_id" {
  type    = string
  default = "Z0877469G22ONKJVD4FZ" # L'ID de la zone Route 53
}

variable "ecr_repository_name" {
  type    = string
  default = "your-website" # Remplacez par le nom souhaité pour le repository ECR
}

variable "task_family" {
  type    = string
  default = "your-website-task" # Remplacez par le nom souhaité pour la famille de tâches ECS
}

variable "cluster_name" {
  type    = string
  default = "your-preprod" # Remplacez par le nom souhaité pour le cluster ECS
}

variable "service_name" {
  type    = string
  default = "your-website-service" # Remplacez par le nom souhaité pour le service ECS
}