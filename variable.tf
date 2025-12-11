variable "region" {
  default = "ap-south-1"
}

variable "az1" {
  default = "ap-south-1a"
}

variable "az2" {
  default = "ap-south-1b"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# 3-tier CIDRs
variable "public_cidr" {
  default = "10.0.1.0/24"
}

variable "app_cidr" {
  default = "10.0.2.0/24"
}

variable "db_cidr" {
  default = "10.0.3.0/24"
}

variable "project_name" {
  default = "FCT"
}

variable "ami" {
  default = "ami-03695d52f0d883f65"
}

variable "instance" {
  default = "t2.micro"
}

variable "key" {
  default = "terraformkey"
}
