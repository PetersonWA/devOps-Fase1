# Infraestrutura como Código (IaC) - Terraform

provider "aws" {
  region = var.region
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Exemplo de AMI (Amazon Linux 2)
  instance_type = "t2.micro"

  tags = {
    Name = "DevOpsFase1-Server"
  }
}

resource "aws_s3_bucket" "static_assets" {
  bucket = "devops-fase1-assets-${random_id.id.hex}"
}

resource "random_id" "id" {
  byte_length = 4
}
