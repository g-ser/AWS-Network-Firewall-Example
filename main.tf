# This terraform configuration file creates an AWS Network Firewall

terraform {
  required_version = ">= 1.3.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.34.0"
    }
  }
}

# Configure the AWS Provider and credentials
provider "aws" {
  region                   = var.region
  shared_credentials_files = [var.credentials_location]
}

# Create a VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Network Firewall VPC"
  }
}

# Create firewall subnet
resource "aws_subnet" "firewall_subnet" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.firewall_subnet_cidr_block
  tags = {
    Name = "firewall_subnet"
  }
}

# Create protected subnet 
resource "aws_subnet" "protected_subnet" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.protected_subnet_cidr_block
  map_public_ip_on_launch = true
  tags = {
    Name = "protected_subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# Create firewall route table
resource "aws_route_table" "firewall_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "Firewall_RT"
  }
}

# Create protected route table
resource "aws_route_table" "protected_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    # In this case the vpc_endpoind_id is the identifier of the firewall endpoint that AWS Network Firewall has instantiated in the firewall subnet
    vpc_endpoint_id = (aws_networkfirewall_firewall.this.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[0]
  }

  tags = {
    Name = "Protected_RT"
  }
}

# Create Internet Gateway route table
resource "aws_route_table" "igw_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = var.protected_subnet_cidr_block
    # In this case the vpc_endpoind_id is the identifier of the firewall endpoint that AWS Network Firewall has instantiated in the firewall subnet
    vpc_endpoint_id = (aws_networkfirewall_firewall.this.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[0]    
  }

  tags = {
    Name = "IGW_RT"
  }
}

# Associate the firewall subnet to the firewall route table
resource "aws_route_table_association" "firewall_route_subnet_association" {
  subnet_id      = aws_subnet.firewall_subnet.id
  route_table_id = aws_route_table.firewall_rt.id
}

# Associate the protected subnet to the protected route table
resource "aws_route_table_association" "protected_route_subnet_association" {
  subnet_id      = aws_subnet.protected_subnet.id
  route_table_id = aws_route_table.protected_rt.id
}

# Internet Gateway Route table association
resource "aws_route_table_association" "igw_route_subnet_association" {
  gateway_id     = aws_internet_gateway.this.id
  route_table_id = aws_route_table.igw_rt.id
}

# Create Network Firewall 

resource "aws_networkfirewall_firewall" "this" {
  name                = "AWSNetworkFirewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.my_fw_policy.arn
  vpc_id              = aws_vpc.this.id
  subnet_mapping {
    subnet_id = aws_subnet.firewall_subnet.id
  }

  tags = {
    Name = "AWSNetworkFirewall"
  }
}



# Create security group for the web server

resource "aws_security_group" "protected" {
  name        = "allow_web_traffic"
  description = "Allow web http traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "protected"
  }
}

# Create the interface of the EC2 instance which will play 
# the role of the web server

resource "aws_network_interface" "web_server_iface" {
  subnet_id       = aws_subnet.protected_subnet.id
  private_ips     = [var.web_server_ip_address]
  security_groups = [aws_security_group.protected.id]

  tags = {
    Name = "web_server_iface"
  }
}

# Get latest Amazon Linux 2 AMI 

data "aws_ami" "latest_amzn2_ami" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-hvm-*-x86_64-gp2"]
  }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
  
  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

# Create Web Server

resource "aws_instance" "web_server" {
  depends_on = [aws_route_table.protected_rt, aws_route_table.igw_rt]

  ami           = data.aws_ami.latest_amzn2_ami.id
  instance_type = var.web_server_instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.web_server_iface.id
    device_index         = 0
  }

  user_data            = data.cloudinit_config.docker_host.rendered
  iam_instance_profile = aws_iam_instance_profile.ssm_iam_profile.name
  tags = {
    Name = "Web Server"
  }
}

# Firewall policy 

resource "aws_networkfirewall_firewall_policy" "my_fw_policy" {
  name = "myFwPolicy"

  firewall_policy {
    # if the packet doesn't match any stateless rule then forward it for stateful inspection
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateless_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.stateless.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful.arn
    }
  }

  tags = {
    Name = "my_fw_policy"
  }
}

# Stateful rule group 

resource "aws_networkfirewall_rule_group" "stateful" {
  capacity = 50
  name     = "StatefulRuleGroup"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "PROTECTED_SUBNET"
        ip_set {
          definition = [var.protected_subnet_cidr_block]
        }
      }
    }
    rules_source {
      rules_string = <<EOF
pass http any any -> $PROTECTED_SUBNET any (msg: "All http traffic towards protected subnet is permitted"; sid: 100; rev:1;)
pass http $PROTECTED_SUBNET any -> any any (msg: "All http traffic from protected subnet to anywhere is permitted"; sid: 200; rev:1;)
pass tls $PROTECTED_SUBNET any -> any any (msg: "All tls traffic from protected subnet to anywhere is permitted"; sid: 300; rev:1;)
pass ftp $PROTECTED_SUBNET any -> any any (msg: "All ftp traffic from protected subnet to anywhere is permitted"; sid: 400; rev:1;)
drop ip any any <> $PROTECTED_SUBNET any (flow:established,to_server; msg: "Block all traffic"; sid:500; rev:1;)
EOF
    }
  }
  tags = {
    Name = "StatefulRuleGroup"
  }
}


# Stateless rule group

resource "aws_networkfirewall_rule_group" "stateless" {
  description = "Stateless Rule Group that forwards everything to stateful rule group"
  capacity    = 50
  name        = "StatelessRuleGroup"
  type        = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 10
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }

  tags = {
    Name = "StatelessRuleGroup"
  }
}
