# credentials for connecting to AWS
credentials_location = "~/.aws/credentials"

# key for connecting to EC2 instances for managing them
key_name = "gs_key_pair"

# VPC
region         = "eu-north-1"
vpc_cidr_block = "10.0.0.0/16"

# subnets
firewall_subnet_cidr_block  = "10.0.1.0/28"
protected_subnet_cidr_block = "10.0.0.0/24"

# web server
web_server_ip_address = "10.0.0.4"
web_server_instance_type = "t3.micro"


