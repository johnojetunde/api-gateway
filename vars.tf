
variable "jwt_issuer_endpoint" {
  type = string
}

variable "jwt_audience" {
  type        = list(string)
  description = "E.g Cognito app client id"
}