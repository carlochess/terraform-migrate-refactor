resource "aws_ssm_parameter" "secret" {
  name        = "/api/charla"
  description = "nothing"
  type        = "String"
  value       = "random() is always 4"
}