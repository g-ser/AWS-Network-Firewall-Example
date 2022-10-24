variable "region" {
  description = "The AWS region where the infrastructure will be provisioned"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The cidr block of the VPC"
  type        = string
}

variable "protected_subnet_cidr_block" {
  description = "The cidr block of the private subnet"
  type        = string
}

variable "firewall_subnet_cidr_block" {
  description = "The cidr block of the public subnet"
  type        = string
}

variable "credentials_location" {
  description = "The location in your local machine of the aws_access_key_id and aws_secret_access_key"
  type        = string
}

variable "web_server_ip_address" {
  description = "The IP address of the 2nd worker node of the k8s cluster."
  type        = string
}

variable "web_server_instance_type" {
  description = "The instance type of the master node"
  type        = string
}

variable "key_name" {
  description = "Key name of the key pair used to connect to EC2 instances"
  type        = string
}
