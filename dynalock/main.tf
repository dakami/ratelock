# IAM policy
#
# Example:
# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
#
resource "aws_iam_role_policy" "Dynalock_ratelock" {
    name = "Dynalock_RatelockPolicy"
    path = "/"
    description = "policy required for ratelock"
    policy =  "${file("iam.json")}"
}


# IAM policy attachment
#
# Example:
# https://www.terraform.io/docs/providers/aws/r/iam_policy_attachment.html
#
#resource "aws_iam_policy_attachment" "Dynalock_ratelock" {
#    name = "Dynalock_RatelockPolicyAttachment"
#    roles = ["${aws_iam_role.Dynalock_iam_for_lambda.name}"]
#    policy_arn = "${aws_iam_policy.Dynalock_ratelock.arn}"
#}


# AWS Lambda Function
#
# Example:
# https://www.terraform.io/docs/providers/aws/r/lambda_function.html
#
resource "aws_iam_role" "Dynalock_iam_for_lambda" {
    name = "Dynalock_iam_for_lambda"
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
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dynamodb.amazonaws.com"
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
resource "aws_lambda_function" "Dynalock_ratelimit_lambda" {
    filename = "dynalock.zip"
    function_name = "dynalock"
    role = "${aws_iam_role.Dynalock_iam_for_lambda.arn}"
    handler = "dynalock.handler"
    runtime = "python2.7" 
    source_code_hash = "${base64sha256(file("dynalock.zip"))}"
}


# AWS Dynamo table setup
#
# Example: 
# https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html
#
# read/write capacity
# http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ProvisionedThroughput.html
#
resource "aws_dynamodb_table" "Dynalock_basic-dynamodb-table" {
    name = "Dynalock_ratelock_dynamo"
    read_capacity = 5
    write_capacity = 5
    hash_key = "username"
    attribute {
      name = "username"
      type = "S"
    }
}