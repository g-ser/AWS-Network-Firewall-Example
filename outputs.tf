output "instance_id_web_server" {
  description = "EC2 instance ID of web server"
  value       = aws_instance.web_server.id
}

output "public_dns_web_server" {
  description = "Public DNS name assigned to the web server instance"
  value       = join("", ["http://", aws_instance.web_server.public_dns])
}

output "public_ip_web_server" {
  description = "Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

