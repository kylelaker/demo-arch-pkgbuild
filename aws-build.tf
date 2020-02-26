provider "aws" {
  region  = var.aws_region
  profile = var.r53_profile_name
}

provider "aws" {
  alias = "r53"
  region  = var.aws_region
  profile = var.r53_profile_name
}

provider "aws" {
  alias = "ec2"
  region  = var.aws_region
  profile = var.ec2_profile_name
}

data "aws_route53_zone" "domain" {
  provider = aws.r53

  name = "${var.domain}."
}

data "aws_vpc" "default_vpc" {
  provider = aws.ec2
  default  = true
}

data "aws_ami" "uplink_ami" {
  provider    = aws.ec2
  owners      = ["093273469852"] # Uplink Labs
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["arch-linux-hvm-*"]
  }
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

  ingress {
    description = "Allow SSH from JMU and home"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [
      # Go Dukes!!
      "134.126.0.0/16",
      var.my_home_cidr
    ]
  }

  ingress {
    description = "Allow ICMP from anywhere"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow egress anywhere"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "arch" {
  provider = aws.ec2

  ami           = data.aws_ami.uplink_ami.image_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.arch_ssh_access.id]

  key_name  = aws_key_pair.arch_ssh.key_name
  user_data = file(var.userdata_file)

  tags = {
    Purpose = "UUG"
    Name    = format("UUG-ARCH-%02d", count.index + 1)
  }

  count = var.attendee_count
}

resource "aws_route53_record" "arch-r53" {
  provider = aws.r53
  count    = var.attendee_count
  zone_id  = data.aws_route53_zone.domain.zone_id
  name     = format("arch%02d.uug", count.index + 1)
  type     = "A"
  ttl      = "60"
  records  = ["${element(aws_instance.arch.*.public_ip, count.index)}"]
}
