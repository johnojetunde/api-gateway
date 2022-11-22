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

resource "aws_apigatewayv2_stage" "v1" {
  api_id = aws_apigatewayv2_api.example.id
  name = "v1"
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