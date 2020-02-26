data "aws_route53_zone" "domain" {
    name = "${var.domain}."
}

resource "aws_security_group" "arch_ssh_access" {
    name        = "arch-ssh-access-uug"
    description = "Allow inbound traffic from home and JMU"
    vpc_id      = var.vpc_id
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [
            # Go Dukes!!
            "134.126.0.0/16",
            var.my_home_cidr
        ]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "arch" {
    ami            = var.ami_id
    instance_type  = "t3.micro"

    vpc_security_group_ids = [aws_security_group.arch_ssh_access.id]

    key_name  = var.key_name
    user_data = file("arch-userdata.sh")

    tags = {
        Purpose = "UUG"
        Name = "UUG-ARCH-${count.index}"
    }

    count = var.attendee_count
}

resource "aws_route53_record" "arch-r53" {
    count   = var.attendee_count
    zone_id = data.aws_route53_zone.domain.zone_id
    name    = "arch${count.index}.uug"
    type    = "A"
    ttl     = "60"
    records = ["${element(aws_instance.arch.*.public_ip, count.index)}"]
}
