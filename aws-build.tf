provider "aws" {
    region = "us-east-1"
}

provider "aws" {
    alias   = "r53"
    # us-east-1 (Northern Virginia) is the only supported region currently
    region  = "us-east-1"
    profile = var.r53_profile_name
}

provider "aws" {
    alias   = "ec2"
    # us-east-1 (Northern Virginia) is the only supported region currently
    region  = "us-east-1"
    profile = var.ec2_profile_name
}

data "aws_route53_zone" "domain" {
    provider = aws.r53

    name     = "${var.domain}."
}

data "aws_vpc" "default_vpc" {
    provider = aws.ec2
    default  = true
}

resource "aws_key_pair" "arch_ssh" {
    provider        = aws.ec2
    key_name_prefix = "archaccesskey"
    public_key      = file(var.pubkey_file)
}

resource "aws_security_group" "arch_ssh_access" {
    provider    = aws.ec2
    name        = "arch-ssh-access-uug"
    description = "Allow inbound traffic from home and JMU"
    vpc_id      = data.aws_vpc.default_vpc.id

    # Allow SSH from JMU and home
    ingress {
        protocol    = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_blocks = [
            # Go Dukes!!
            "134.126.0.0/16",
            var.my_home_cidr
        ]
    }

    # Allow ICMP from anywhere
    ingress {
        protocol    = "icmp"
        from_port   = -1
        to_port     = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow egress to anywhere (Terraform removes the default equivalent rule)
    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "arch" {
    provider       = aws.ec2

    ami            = var.ami_id
    instance_type  = var.instance_type

    vpc_security_group_ids = [aws_security_group.arch_ssh_access.id]

    key_name  = aws_key_pair.arch_ssh.key_name
    user_data = file(var.userdata_file)

    tags = {
        Purpose = "UUG"
        Name = "UUG-ARCH-${count.index}"
    }

    count = var.attendee_count
}

resource "aws_route53_record" "arch-r53" {
    provider = aws.r53
    count    = var.attendee_count
    zone_id  = data.aws_route53_zone.domain.zone_id
    name     = "arch${count.index}.uug"
    type     = "A"
    ttl      = "60"
    records  = ["${element(aws_instance.arch.*.public_ip, count.index)}"]
}
