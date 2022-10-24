# Motivation

The purpose of this repo is to experiment with AWS Network Firewall. The content of this repo is based on the following post on AWS's Security Blog: [Hands-on walkthrough of the AWS Network Firewall](https://aws.amazon.com/blogs/security/hands-on-walkthrough-of-the-aws-network-firewall-flexible-rules-engine/). The main difference is that instead of using AWS CloudFormation the chosen IaC tool of this repo is Terraform. 

# What's inside this repo<a name="repo_content"></a>

This repo contains terraform configuration files for provisioning a VPC, an AWS Network Firewall and a single EC2 instance which acts as a web server inside a protected subnet. 

# Prerequisites for working with the repo<a name="prerequisites"></a>

* Your local machine, has to have terraform installed so you can run the terraform configuration files included in this repository. This repo has been tested with terraform 1.3.2
* You need to generate a pair of aws_access_key_id-aws_secret_access_key for your AWS user using the console of AWS and provide the path where the credentials are stored to the variable called ```credentials_location``` which is in ```terraform.tfvars``` file. This is used by terraform to make programmatic calls to AWS API.
* You need to use AWS console (prior to running the terraform configuration files) to generate a key-pair whose name you need to specify in the ``terraform.tfvars`` file (variable name is ```key_name```). The ```pem``` file (which has to be downloaded from AWS and stored on your local machine) of the key pair, is used for accessing the EC2 Web Server instance with ssh (via AWS SSM)
* Go through the section [Accessing the Web Server](#access_instance) and make sure that you have [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), as well as [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and the proper configuration in ```~/.ssh/config``` and ```~/.aws/config``` files. 


# Accessing the Web Server<a name="access_instance"></a>

Although the AWS security group where the Web Server instance is placed includes only one ingress rule for allowing web traffic; using SSH to connect to the instance is still possible thanks to AWS Systems Manager. Terraform installs SSM Agent on the Web Server instance.   

### Interact with the Web Server using the CLI via SSH

In order for a client (e.g. you local machine) to ssh to the EC2 instances, it needs to fullfil the below:

* Have AWS CLI installed: [Installation of AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Have the Session Manager plugin for the AWS CLI installed: [Install the Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
* Have the configuration below into the SSH configuration file of your local machine (typically located at ```~/.ssh/config```)
```shell
# SSH over Session Manager
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```
* Specify in the ```~/.aws/config``` file the AWS region like below:
```shell
[default]
region=<AWS_REGION>
```
You can connect using the command: ```ssh -i <KEY_PEM_FILE> <USER_NAME>@<INSTANCE_ID_WEB_SERVER>```
The ```USER_NAME``` of the Web Server is ```ec2-user```. The ```KEY_PEM_FILE``` is the path pointing to the pem file of the key-pair that you need to generate as discussed in the [Prerequisites for working with the repo](#prerequisites) section.
When terraform finishes its execution, it returns  the ```instance_id_web_server```.
# Architecture<a name="architecture"></a>

A high level view of the virtual infrastructure which will be created by the terraform configuration files included in this repo can be seen in the picture below: 

 ![High Level Setup](/assets/images/AWS-Network-Firewall-Example.jpg)
 #### Notes
- Subnet 10.0.0.0/24 is protected in the sense that is behind the firewall endpoint. Note that instances that are created inside it do get a public IP (AWS EIP)
- Subnet 10.0.1.0/28 is the firewall subnet (i.e. the subnet where the firewall endpoint is located)
- The default route of the protected subnet is the identifier of the firewall endpoint 
- The default route of the firewall subnet is the Internet Gateway (IGW)
- The web server is placed in a security group called ```allow_web_traffic``` that:
  - Allows inbound only http traffic
  - It allows all outbound traffic 

# Provision the infrastructure

### Run terraform
In the root folder folder run:
```terraform apply```