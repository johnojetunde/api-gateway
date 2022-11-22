provider "aws" {
  region = "eu-west-2"
  endpoints {
    sts = "https://sts.eu-west-2.amazonaws.com"
  }
}

resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "v1" {
  api_id = aws_apigatewayv2_api.example.id
  name   = "example-stage"
}

resource "aws_apigatewayv2_integration" "v1" {
  api_id           = aws_apigatewayv2_api.example.id
  integration_type = "HTTP_PROXY"

  integration_method = "ANY"
  integration_uri    = "https://developers.pleo.io/reference/introduction"
}

resource "aws_apigatewayv2_route" "v1" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "ANY /v3"

  target = "integrations/${aws_apigatewayv2_integration.v1.id}"
}