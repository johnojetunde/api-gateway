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

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "my-tf-test-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_jwt_verifier" {
  type = "zip"

  source_dir  = "${path.module}/jwt-verifier"
  output_path = "${path.module}/jwt-verifier.zip"
}


resource "aws_s3_object" "lambda_jwt_verifier" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "jwt-verifier.zip"
  source = data.archive_file.lambda_jwt_verifier.output_path

  etag = filemd5(data.archive_file.lambda_jwt_verifier.output_path)
}


resource "aws_lambda_function" "lambda_jwt_verifier" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_jwt_verifier.key

  runtime = "nodejs12.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda_jwt_verifier.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "lambda_jwt_verifier" {
  name = "/aws/lambda/${aws_lambda_function.lambda_jwt_verifier.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}