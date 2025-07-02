provider "aws" {
  region = "us-east-2"
}

# Locals
locals {
  ami_id        = "ami-0b05d988257befbbe" # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "my_key"

 
  instances = {
    jenkins_master     = {}
    jenkins_slave      = {}
    ansible_controller = {}
    kube_master        = {}
    kube_node1         = {}
    kube_node2         = {}
  }
}

# VPC & Networking
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "custom-vpc" }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "custom-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "custom-igw" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "custom-rt" }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "instances" {
  for_each = local.instances

  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.subnet.id
  key_name                    = local.key_name
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  associate_public_ip_address = true


lifecycle {
    prevent_destroy = true
  }


  tags = {
    Name = title(replace(each.key, "_", " "))
  }
}

 

# Output Public IPs
output "instance_ips" {
  value = {
    for name, instance in aws_instance.instances :
    name => instance.public_ip
  }
}
