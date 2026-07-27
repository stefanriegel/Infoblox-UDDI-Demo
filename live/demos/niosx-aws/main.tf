terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # handed to cloud-init directly as user-data.
  user_data = <<-EOT
    #cloud-config
    host_setup:
      jointoken: ${var.niosx_join_token}
      tags:
        - demo=true
        - automation=github-actions
        - hostname=${var.name}
  EOT
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name       = "vpc-${var.name}"
    demo       = "true"
    automation = "github-actions"
    ManagedBy  = "terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.name}"
    demo = "true"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = aws_vpc.main.cidr_block
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "snet-${var.name}"
    demo = "true"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rt-${var.name}"
    demo = "true"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "niosx" {
  name        = "${var.name}-sg"
  description = "NIOS-X server - outbound to Infoblox Portal, DNS from ${var.dns_client_cidr}"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "All outbound (Infoblox Portal, updates)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.dns_client_cidr]
  }

  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.dns_client_cidr]
  }

  tags = {
    Name = "sg-${var.name}"
    demo = "true"
  }
}

resource "aws_instance" "niosx" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.niosx.id]
  associate_public_ip_address = true
  user_data                   = local.user_data

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name       = var.name
    demo       = "true"
    automation = "github-actions"
    ManagedBy  = "terraform"
    product    = "niosx"
  }
}

output "instance_id" {
  value       = aws_instance.niosx.id
  description = "EC2 instance ID of the NIOS-X server"
}

output "public_ip" {
  value       = aws_instance.niosx.public_ip
  description = "Public IP used to reach the Infoblox Portal"
}

output "private_ip" {
  value       = aws_instance.niosx.private_ip
  description = "Private IP inside the demo VPC"
}

output "instance_type" {
  value       = aws_instance.niosx.instance_type
  description = "EC2 instance type"
}

output "availability_zone" {
  value       = aws_instance.niosx.availability_zone
  description = "Availability zone the server runs in"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "Demo VPC ID"
}
