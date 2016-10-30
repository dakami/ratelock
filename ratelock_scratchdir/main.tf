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
resource "aws_lambda_function" "ratelimit_lambda" {
    filename = "ratelock.zip"
    function_name = "ratelimit"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "ratelock.handler"
    runtime = "python2.7" 
    source_code_hash = "${base64sha256(file("ratelock.zip"))}"
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
# You do not need to specify non-key attributes when creating a DynamoDB table. DynamoDB does not have a fixed schema. Instead, each data item may have a different number of attributes (aside from the mandatory key attributes).
#    attribute {
#      name = "password"
#      type = "S"
#    }
}


# AWS API Gateway Setup

resource "aws_lambda_permission" "allow_api_gateway" {
    function_name = "${aws_lambda_function.ratelimit_lambda.function_name}"
    statement_id = "AllowExecutionFromApiGateway"
    action = "lambda:InvokeFunction"
    principal = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_rest_api" "ratelimit_api" {
  name = "RateLimitAPI"
  description = "This is the RateLimit API"
}

resource "aws_api_gateway_resource" "ratelimit" {
  rest_api_id = "${aws_api_gateway_rest_api.ratelimit_api.id}"
  parent_id = "${aws_api_gateway_rest_api.ratelimit_api.root_resource_id}"
  path_part = "ratelimit"
}

resource "aws_api_gateway_method" "ratelimit-get" {
  rest_api_id = "${aws_api_gateway_rest_api.ratelimit_api.id}"
  resource_id = "${aws_api_gateway_resource.ratelimit.id}"
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ratelimit-get-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.ratelimit_api.id}"
  resource_id = "${aws_api_gateway_resource.ratelimit.id}"
  http_method = "${aws_api_gateway_method.ratelimit-get.http_method}"
  type = "AWS"
  uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:561759691730:function:ratelimit/invocations"
  integration_http_method = "${aws_api_gateway_method.ratelimit-get.http_method}"
}
