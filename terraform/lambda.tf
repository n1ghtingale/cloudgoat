resource "aws_iam_role" "lambda_iam" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_iam_policy" {
  name = "policy_for_lambda_role"
  role = "${aws_iam_role.lambda_iam.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*",
        "efs:*",
        "cloudtrail:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda_function.zip"
  function_name    = "lambda_function"
  role             = "${aws_iam_role.lambda_iam.arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${filebase64sha256("lambda_function.zip")}"
  runtime          = "python3.6"
}

#Custom challenge
# Lambda functions code
data "archive_file" "lambda-function-challenge1" {
    type = "zip"
    source_file = "./lambda_challenge1.py"
    output_path = "./lambda_challenge1.zip"
}

data "archive_file" "lambda-function-challenge4" {
    type = "zip"
    source_file = "./lambda_challenge4.py"
    output_path = "./lambda_challenge4.zip"
}



# Lambda roles
resource "aws_iam_role" "lambda-role-challenge1" {
    name = "LambdaRoleForVulnerableFunction"
    force_detach_policies = true
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role" "lambda-role-challenge2" {
    name = "LambdaEC2FullAccess"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": ["lambda.amazonaws.com", "cloudformation.amazonaws.com"]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role" "lambda-role-challenge4" {
    name = "LambdaVPCAccess"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}



# Lambda role policies
resource "aws_iam_policy" "lambda-role-policy-challenge1" {
    name = "BasicExecutionRoleWithS3FullAccess"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "lambda-role-policy-challenge2" {
    name = "EC2FullAccess"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "cloudwatch:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "autoscaling.amazonaws.com",
                        "ec2scheduled.amazonaws.com",
                        "elasticloadbalancing.amazonaws.com",
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com",
                        "transitgateway.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_policy" "lambda-role-policy-challenge4" {
    name = "AWSLambdaVPCAccessExecutionRole"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


# Role policy attachments
resource "aws_iam_role_policy_attachment" "lambda-policy-attachment-challenge1" {
    role       = "${aws_iam_role.lambda-role-challenge1.name}"
    policy_arn = "${aws_iam_policy.lambda-role-policy-challenge1.arn}"
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attachment-challenge2" {
    role       = "${aws_iam_role.lambda-role-challenge2.name}"
    policy_arn = "${aws_iam_policy.lambda-role-policy-challenge2.arn}"
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attachment-challenge4" {
    role       = "${aws_iam_role.lambda-role-challenge4.name}"
    policy_arn = "${aws_iam_policy.lambda-role-policy-challenge4.arn}"
}



# Lambda functions
resource "aws_lambda_function" "lambda-function-challenge1" {
    filename          = "./lambda_challenge1.zip"
    function_name     = "VulnerableFunction"
    role              = "${aws_iam_role.lambda-role-challenge1.arn}"
    handler           = "lambda_challenge1.handler"
    source_code_hash  = "${data.archive_file.lambda-function-challenge1.output_base64sha256}"
    runtime           = "python3.7"
    environment {
        variables = {
            app_secret = "1234567890"
        }
    }
}

resource "aws_lambda_function" "lambda-function-challenge4" {
    filename          = "./lambda_challenge4.zip"
    function_name     = "Challenge4"
    role              = "${aws_iam_role.lambda-role-challenge4.arn}"
    handler           = "lambda_challenge4.handler"
    source_code_hash  = "${data.archive_file.lambda-function-challenge4.output_base64sha256}"
    runtime           = "python3.7"
    vpc_config {
        subnet_ids = ["${aws_subnet.subnet1.id}", "${aws_subnet.subnet2.id}"]
        security_group_ids = ["${aws_security_group.security-group1.id}"]
    }
}



# Lambda permission
resource "aws_lambda_permission" "lambda-permission" {
    statement_id  = "LambdaTriggerOnS3Upload"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lambda-function-challenge1.arn}"
    principal     = "s3.amazonaws.com"
    source_arn    = "${aws_s3_bucket.lambda-s3-bucket.arn}"
}

