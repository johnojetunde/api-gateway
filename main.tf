provider "aws" {
  region = "eu-west-2"
  access_key = var.AWS_ACCESS_KEY
  //"AKIAVGV47FPSHKRSQ652"
  secret_key =  var.AWS_ACCESS_KEY

  //"01HsxHkHMtd06Ge2lIw3Rn9nHfpWwp+uWBO0111B"
  endpoints {
    sts = "https://sts.eu-west-2.amazonaws.com"
  }
}

resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}
