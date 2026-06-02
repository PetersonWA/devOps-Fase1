variable "region" {
  description = "Região da AWS para o provisionamento"
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Nome da instância EC2"
  default     = "AppServer-DevOps"
}
