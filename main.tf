provider "aws" {
  region = "eu-west-2"
  endpoints {
    sts = "https://sts.eu-west-2.amazonaws.com"
  }
}

resource "aws_apigatewayv2_api" "example" {
  name = "example-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "version1-staging-api" {
  api_id = aws_apigatewayv2_api.example.id
  integration_type = "HTTP_PROXY"

  integration_method = "ANY"
  integration_uri = "https://openapi.staging.pleo.io/v1/{proxy}"
}

resource "aws_apigatewayv2_route" "stagingv1" {
  api_id = aws_apigatewayv2_api.example.id
  route_key = "ANY /v1/{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.version1-staging-api.id}"
}

resource "aws_apigatewayv2_stage" "staging" {
  api_id = aws_apigatewayv2_api.example.id
  name = "staging"
  auto_deploy = true

  access_log_settings {
    destination_arn = "arn:aws:logs:eu-west-2:357952334820:log-group:/aws/lambda/jwt-verifier"
    format = "{ \"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\",\"routeKey\":\"$context.routeKey\", \"status\":\"$context.status\",\"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\"}"
  }

  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit = 200
    data_trace_enabled = true
    detailed_metrics_enabled = true
  }
}

data "aws_caller_identity" "current_user" {}

//resource "aws_s3_bucket" "lambda_jwt_bucket" {
//  bucket = "johnojetunde-my-tf-test-bucket-2022"
//
//  tags = {
//    Name        = "My bucket"
//    Environment = "Dev"
//  }
//}
//
//resource "aws_s3_bucket_acl" "lambda_jwt_bucket_acl" {
//  bucket = aws_s3_bucket.lambda_jwt_bucket.id
//  acl    = "private"
//}
//
//resource "aws_s3_object" "lambda_jwt_verifier" {
//  bucket = aws_s3_bucket.lambda_jwt_bucket.id
//
//  key    = "jwt-verifier.zip"
//  source = "${path.module}/jwt-verifier.zip"
//
//  etag = filemd5("${path.module}/jwt-verifier.zip")
//}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
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

resource "aws_lambda_function" "lambda_jwt_verifier" {
  function_name = "LambdaJwtVerifier"

  s3_bucket = "lamda-jwt-verifier"
  s3_key    = "jwt-verifier.zip"

  runtime = "nodejs12.x"
  handler = "index.handler"

  source_code_hash = filebase64sha256("${path.module}/jwt-verifier.zip")

  role = aws_iam_role.lambda_role.arn
}

resource "aws_cloudwatch_log_group" "lambda_jwt_verifier" {
  name = "/aws/lambda/${aws_lambda_function.lambda_jwt_verifier.function_name}"

  retention_in_days = 30
}

