resource "aws_key_pair" "cloudgoat_key" {
  key_name = "cloudgoat_key"
  public_key = "${var.ec2_public_key}"
}

resource "aws_instance" "cloudgoat_instance" {
  ami = "${var.ami_id}"
  count = 1
  instance_type = "t2.micro"
  disable_api_termination = false
  security_groups = ["${aws_security_group.cloudgoat_ec2_sg.name}"]
  iam_instance_profile = "${aws_iam_instance_profile.cloudgoat_instance_profile.id}"
  key_name = "cloudgoat_key"

  user_data = "#!/bin/bash\nyum update -y\nyum install php -y\nyum install httpd -y\nmkdir -p /var/www/html\ncd /var/www/html\nrm -rf ./*\nprintf \"<?php\\nif(isset(\\$_POST['url'])) {\\n  if(strcmp(\\$_POST['password'], '${var.ec2_web_app_password}') != 0) {\\n    echo 'Wrong password. You just need to find it!';\\n    die;\\n  }\\n  echo '<pre>';\\n  echo(file_get_contents(\\$_POST['url']));\\n  echo '</pre>';\\n  die;\\n}\\n?>\\n<html><head><title>URL Fetcher</title></head><body><form method='POST'><label for='url'>Enter the password and a URL that you want to make a request to (ex: https://google.com/)</label><br /><input type='text' name='password' placeholder='Password' /><input type='text' name='url' placeholder='URL' /><br /><input type='submit' value='Retrieve Contents' /></form></body></html>\" > index.php\n/usr/sbin/apachectl start"
}

resource "aws_security_group" "cloudgoat_ec2_sg" {
  name = "cloudgoat_ec2_sg"
  description = "SG for EC2 instances"
}

resource "aws_security_group_rule" "ssh_in" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks = ["${file("../tmp/allow_cidr.txt")}"]
  security_group_id = "${aws_security_group.cloudgoat_ec2_sg.id}"
}

resource "aws_security_group_rule" "allow_all_out" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cloudgoat_ec2_sg.id}"
}

resource "aws_security_group" "cloudgoat_ec2_debug_sg" {
  name = "cloudgoat_ec2_debug_sg"
  description = "Debug SG for EC2 instances"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${file("../tmp/allow_cidr.txt")}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_policy" "ec2_ip_policy" {
  name = "ec2_ip_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:CreatePolicyVersion"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_ip_attachment" {
  role       = "${aws_iam_role.ec2_role.name}"
  policy_arn = "${aws_iam_policy.ec2_ip_policy.arn}"
}

resource "aws_iam_instance_profile" "cloudgoat_instance_profile" {
  name = "cloudgoat_ec2_iam_profile"
  role = "${aws_iam_role.ec2_role.name}"
}

#Custom challenge
resource "aws_key_pair" "ec2-key-pair" {
    key_name = "ec2-key-pair-${var.cgid}"
    public_key = "${file(var.ssh-public-key-for-ec2)}"
}

resource "aws_instance" "ubuntu" {
    ami = "ami-0dad20bd1b9c8c004"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.subnet2.id}"
    associate_public_ip_address = true
    key_name = "${aws_key_pair.ec2-key-pair.key_name}"
    vpc_security_group_ids = ["${aws_security_group.security-group1.id}"]
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
    provisioner "file" {
        source = "./index.html"
        destination = "/home/ubuntu/index.html"
    }
    provisioner "local-exec" {
        command = "ssh -o 'StrictHostKeyChecking no' -i ${var.ssh-private-key-for-ec2} ubuntu@${self.public_ip} 'nohup python3 -m http.server 8000 >/dev/null 2>&1 &'"
    }
    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.ssh-private-key-for-ec2)}"
        host = self.public_ip
        timeout = "1m"
    }
}

