terraform {
  backend "s3" {
    bucket = "mypersonalportfolio1"
    key    = "terraformkey"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.region
}


# VPC

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project_name}-vpc"
  }
}


# SUBNETS (3-tier)


# Web Tier (Public)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_cidr
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# App Tier (Private 1)
resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.app_cidr
  availability_zone = var.az1

  tags = {
    Name = "${var.project_name}-app-subnet"
  }
}

# DB Tier (Private 2)
resource "aws_subnet" "db_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.db_cidr
  availability_zone = var.az2

  tags = {
    Name = "${var.project_name}-db-subnet"
  }
}


# INTERNET GATEWAY


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}


# PUBLIC ROUTE TABLE

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-public-RT"
  }
}

# Route → Internet
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate Public Subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# NAT GATEWAY FOR PRIVATE SUBNETS

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}


# PRIVATE ROUTE TABLE


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-private-RT"
  }
}

# Route → NAT Gateway
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate App & DB Subnets
resource "aws_route_table_association" "app_subnet_assoc" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "db_subnet_assoc" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.private_rt.id
}


# SECURITY GROUP


resource "aws_security_group" "my_sg" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "${var.project_name}-SG"
  description = "Allow SSH, HTTP, and HTTPS"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 INSTANCES


# Web Server (PUBLIC)
resource "aws_instance" "web_server" {
  ami                    = var.ami
  instance_type          = var.instance
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  key_name               = var.key

  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# App Server (PRIVATE)
resource "aws_instance" "app_server" {
  ami                    = var.ami
  instance_type          = var.instance
  subnet_id              = aws_subnet.app_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  key_name               = var.key

  tags = {
    Name = "${var.project_name}-app-server"
  }
}

# DB Server (PRIVATE)
resource "aws_instance" "db_server" {
  ami                    = var.ami
  instance_type          = var.instance
  subnet_id              = aws_subnet.db_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  key_name               = var.key

  tags = {
    Name = "${var.project_name}-db-server"
  }
}
