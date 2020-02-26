variable "ami_id" {
  default = "ami-074508ad6e83609f9"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "r53_profile_name" {
  type = string
}

variable "ec2_profile_name" {
  type = string
}

variable "my_home_cidr" {
  type = string
}

variable "attendee_count" {
  type = number
}

variable "domain" {
  type = string
}

variable "pubkey_file" {
  type = string
}

variable "userdata_file" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
