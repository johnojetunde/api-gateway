provider "aws" {
  region = "eu-west-2"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_ACCESS_KEY
  endpoints {
    sts = "https://sts.eu-west-2.amazonaws.com"
  }
}

resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}
