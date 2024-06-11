variable "private_key" {
  type = string
}

variable "public_key" {
  type = string
}

variable "aws_region" {
  default = "us-west-2"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "efs_dns_name" {
  type = string
}
