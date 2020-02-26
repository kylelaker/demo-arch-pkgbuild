variable "ami_id" {
    default = "ami-074508ad6e83609f9"
}

variable "vpc_id" {
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

variable "key_name" {
    type = string
}
