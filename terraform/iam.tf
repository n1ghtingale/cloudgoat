#Custom challenge
# Read-only user
resource "aws_iam_user" "readonly" {
    name = "LambdaReadOnlyTester"
    tags = {
        Name = "readonly-${var.cgid}"
    }
}
resource "aws_iam_access_key" "readonly" {
    user = "${aws_iam_user.readonly.name}"
}

# Read-write user with "iam:PassRole" permission
resource "aws_iam_user" "readwrite-passrole" {
    name = "LambdaReadWriteWithPassRoleTester"
    tags = {
        Name = "readwrite-passrole-${var.cgid}"
    }
}
resource "aws_iam_access_key" "readwrite-passrole" {
    user = "${aws_iam_user.readwrite-passrole.name}"
}

# Read-write user without "iam:PassRole" permission
resource "aws_iam_user" "readwrite" {
    name = "LambdaReadWriteTester"
    tags = {
        Name = "readwrite-${var.cgid}"
    }
}
resource "aws_iam_access_key" "readwrite" {
    user = "${aws_iam_user.readwrite.name}"
}



# Policy for read-only user
resource "aws_iam_policy" "policy-readonly" {
    name = "LambdaReadOnlyIAMPolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:List*",
        "lambda:Get*",
        "s3:PutObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Policy for read-write user with "iam:PassRole" permission
resource "aws_iam_policy" "policy-readwrite-passrole" {
    name = "LambdaReadWriteWithPassRoleIAMPolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:*",
        "iam:PassRole",
        "iam:List*",
        "iam:Get*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Policy for read-write user without "iam:PassRole" permission
resource "aws_iam_policy" "policy-readwrite" {
    name = "LambdaReadWriteIAMPolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:*",
        "iam:ListRoles",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}



# User policy attachments
resource "aws_iam_user_policy_attachment" "policy-readonly-attachment" {
    user = "${aws_iam_user.readonly.name}"
    policy_arn = "${aws_iam_policy.policy-readonly.arn}"
}

resource "aws_iam_user_policy_attachment" "policy-readwrite-passrole-attachment" {
    user = "${aws_iam_user.readwrite-passrole.name}"
    policy_arn = "${aws_iam_policy.policy-readwrite-passrole.arn}"
}

resource "aws_iam_user_policy_attachment" "policy-readwrite-attachment" {
    user = "${aws_iam_user.readwrite.name}"
    policy_arn = "${aws_iam_policy.policy-readwrite.arn}"
}

resource "aws_iam_role" "ec2_full_access" {
  name = "ec2_full_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "cloudformation.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}


resource "aws_iam_policy" "policy_ec2_full_access" {
    name = "ec2FullAccessIAMPolicy"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Effect": "Allow",
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

resource "aws_iam_role_policy_attachment" "ec2_full_access_policy_attachment" {
  role       = "${aws_iam_role.ec2_full_access.name}"
  policy_arn = "${aws_iam_policy.policy_ec2_full_access.arn}"
}

resource "aws_iam_user" "cffullaccess" {
    name = "cloudFormationFullAccess"
    tags = {
        Name = "cloudFormationFullAccess"
    }
}

resource "aws_iam_access_key" "cffullaccess" {
    user = "${aws_iam_user.cffullaccess.name}"
}

resource "aws_iam_policy" "cfFullAccessPolicy" {
    name = "cfFullAccessPolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "iam:Get*",
        "iam:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "policy-cffuallaccess-attachment" {
    user = "${aws_iam_user.cffullaccess.name}"
    policy_arn = "${aws_iam_policy.cfFullAccessPolicy.arn}"
}

