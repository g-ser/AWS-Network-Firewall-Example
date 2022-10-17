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
# Canonical, Ubuntu, 22.04 LTS ami
web_server_ami = "ami-0440e5026412ff23f"
# t2.medium instance type covers kubeadm minimun 
# requirements for the master node which are 2 CPUS
# and 1700 MB memory
web_server_instance_type = "t3.micro"


