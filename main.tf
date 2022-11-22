provider "aws" {
  region = "eu-west-2"
  access_key = "AKIAVGV47FPSHKRSQ652"
//  var.AWS_ACCESS_KEY
  secret_key = "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"
  //var.AWS_ACCESS_KEY
  endpoints {
    sts = "https://sts.eu-west-2.amazonaws.com"
  }
}

resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}
