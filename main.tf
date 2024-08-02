terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}
# Instance
resource "aws_instance" "movie-instance-public" {
  ami = "ami-045f2d6eeb07ce8c0"
  instance_type = "t2.micro"
  key_name = "kakao-tech-bootcamp"
  subnet_id = aws_subnet.movie-public1.id
  security_groups = [ aws_security_group.movie-sg-default.id ]
  tags = {
    Name = "public-test"
  }
  
}
resource "aws_instance" "movie-instance-db" {
  ami = "ami-045f2d6eeb07ce8c0"
  instance_type = "t2.micro"
  key_name = "kakao-tech-bootcamp"
  subnet_id = aws_subnet.movie-private-db.id
  security_groups = [aws_security_group.movie-sg-db.id, aws_security_group.movie-sg-default.id ]
  tags = {
    Name = "Private-test"
  }
}


# 보안그룹
resource "aws_security_group" "movie-sg-default" {
  vpc_id = aws_vpc.movie-main.id
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "movie-main-sg"
  }
}

resource "aws_security_group" "movie-sg-db" {
  vpc_id = aws_vpc.movie-main.id
  ingress {
    from_port   = 0
    to_port     = 3306
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
    Name = "movie-db-sg"
  }
}

resource "aws_db_subnet_group" "movie-db-subnet-group" {
  name       = "movie-db-subnet-group"
  subnet_ids = [
    aws_subnet.movie-private1.id,
    aws_subnet.movie-private-db.id
  ]

  tags = {
    Name = "movie-db-subnet-group"
  }
}

# VPC
resource "aws_vpc" "movie-main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "movie-chat-main"
  }
}

resource "aws_internet_gateway" "movie-ig" {
  vpc_id = aws_vpc.movie-main.id
}

# 서브넷
resource "aws_subnet" "movie-public1" {
  vpc_id                  = aws_vpc.movie-main.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"
}

resource "aws_subnet" "movie-private1" {
  vpc_id            = aws_vpc.movie-main.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "movie-private-db" {
  vpc_id = aws_vpc.movie-main.id
  cidr_block = "192.168.5.0/24"
  availability_zone = "ap-northeast-2c"
}

resource "aws_route_table" "moive-rt-db" {
  vpc_id = aws_vpc.movie-main.id

  route {
    # 인터넷으로 나가는 경로
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.movie-nat-gw.id
  }

  tags = {
    name = "movie-rt-db"
  }
}

resource "aws_route_table" "moive-rt-public" {
  vpc_id = aws_vpc.movie-main.id

  route {
    # 인터넷으로 나가는 경로
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.movie-ig.id
  }

  tags = {
    name = "movie-rt-public"
  }
}

resource "aws_route_table_association" "movie-public-rta" {
  subnet_id = aws_subnet.movie-public1.id
  route_table_id = aws_route_table.moive-rt-public.id
}

resource "aws_route_table_association" "movie-db-rta" {
  subnet_id = aws_subnet.movie-private-db.id
  route_table_id = aws_route_table.moive-rt-db.id
}

resource "aws_eip" "movie-main" {
  vpc = true
}
# Nat Gateway
resource "aws_nat_gateway" "movie-nat-gw" {
  allocation_id = aws_eip.movie-main.id
  subnet_id = aws_subnet.movie-public1.id
  connectivity_type = "public"
}

output "instance_ip" {
  value = aws_instance.movie-instance-public.public_ip
}