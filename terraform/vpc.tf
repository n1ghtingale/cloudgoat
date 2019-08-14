#Custom challenge
resource "aws_default_vpc" "default" {
    enable_dns_hostnames = true
}

resource "aws_subnet" "subnet1" {
    vpc_id     = "${aws_default_vpc.default.id}"
    cidr_block = "172.31.48.0/20"
}

resource "aws_subnet" "subnet2" {
    vpc_id     = "${aws_default_vpc.default.id}"
    cidr_block = "172.31.64.0/20"
}

resource "aws_security_group" "security-group1" {
    name        = "security-group1"
    vpc_id      = "${aws_default_vpc.default.id}"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.subnet1.cidr_block}", "${aws_subnet.subnet2.cidr_block}"]
    }

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}
