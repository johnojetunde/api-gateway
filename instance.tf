provider "aws" {
  region = "eu-west-2"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_ACCESS_KEY
}

resource "aws_instance" "web" {
  ami = "ami-02dc8ad50da58fffd"
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}