resource "aws_s3_bucket" "cloudgoat_private" {
  bucket        = "${var.cloudgoat_private_bucket_name}"
  acl           = "private"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.cloudgoat_private_bucket_name}"
        },
        {
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.cloudgoat_private_bucket_name}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "cloudgoat_public" {
  bucket        = "${var.cloudgoat_public_bucket_name}"
  acl           = "public-read"
  force_destroy = true
}

resource "aws_s3_bucket_object" "object" {
  bucket = "${aws_s3_bucket.cloudgoat_public.id}"
  key    = "lorem_ipsum.txt"
  source = "./lorem_ipsum.txt"
  acl    = "public-read"

  etag = "${filemd5("./lorem_ipsum.txt")}"
}

#Custom challenge
resource "aws_s3_bucket" "lambda-s3-bucket" {
    bucket = "bucket-for-lambda-pentesting-${var.cgid}"
    acl = "private"
    force_destroy = true
}

resource "aws_s3_bucket_notification" "bucket-notification" {
    bucket = "${aws_s3_bucket.lambda-s3-bucket.id}"
    lambda_function {
        lambda_function_arn = "${aws_lambda_function.lambda-function-challenge1.arn}"
        events = ["s3:ObjectCreated:*"]
    }
}

