# IAM policy
#
# Example:
# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
#
resource "aws_iam_policy" "ratelock" {
    name = "RatelockPolicy"
    path = "/"
    description = "policy required for ratelock"
    policy =  "${file("iam.json")}"
}


# IAM policy attachment
#
# Example:
# https://www.terraform.io/docs/providers/aws/r/iam_policy_attachment.html
#
resource "aws_iam_policy_attachment" "ratelock" {
    name = "RatelockPolicyAttachment"
    roles = ["${aws_iam_role.iam_for_lambda.name}"]
    policy_arn = "${aws_iam_policy.ratelock.arn}"
}


# AWS Lambda Function
#
# Example:
# https://www.terraform.io/docs/providers/aws/r/lambda_function.html
#
resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"
    assume_role_policy = <<EOF
{
  "Version": "2016-10-26",
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


# Python code ( pushed into AWS lambda function)
#
# role can be a $variable or specified arn like:
# "arn:aws:iam::*:user/walliam/*" 
#
# Workaround: "Ability to zip AWS Lambda function on the fly"
# https://github.com/hashicorp/terraform/issues/8344
# 
resource "aws_lambda_function" "ratelimit_lambda" {
    filename = "dynamo_local_py.zip"
    function_name = "ratelimit"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "ratelimit.handler"
    runtime = "python2.7" 
    source_code_hash = "${base64sha256(file("dynamo_local.zip"))}"
}


# AWS Dynamo table setup
#
# Example: 
# https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html
#
# read/write capacity
# http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ProvisionedThroughput.html
#
resource "aws_dynamodb_table" "basic-dynamodb-table" {
    name = "ratelock"
    read_capacity = 5
    write_capacity = 5
    hash_key = "username"
    attribute {
      name = "username"
      type = "S"
    }
    attribute {
      name = "password"
      type = "S"
    }
}