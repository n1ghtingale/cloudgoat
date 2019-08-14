variable "ami_id" {
  default = "ami-05868579"
}

variable "availability_zone" {
  default = "ap-southeast-1a"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

variable "cloudgoat_private_bucket_name" {
  default = "cloudgoat-bucket-private"
}

variable "cloudgoat_public_bucket_name" {
  default = "cloudgoat-bucket-public"
}

variable "ec2_public_key" {
  default = "no_key_specified"
}

variable "ec2_web_app_password" {
  default = "1234"
}

variable "cgid" {
}

# SSH public key
variable "ssh-public-key-for-ec2" {
    default = "../cloudgoat.pub"
}

# SSH private key
variable "ssh-private-key-for-ec2" {
    default = "../cloudgoat"
}
