output "instance_ip" {
  value       = aws_instance.app_server.public_ip
  description = "IP Público da instância EC2 criada"
}

output "bucket_name" {
  value       = aws_s3_bucket.static_assets.id
  description = "Nome do bucket S3 criado"
}
