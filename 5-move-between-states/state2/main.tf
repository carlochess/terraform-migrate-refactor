# resource "aws_ssm_parameter" "secret" {
#   name        = "/api/charla"
#   description = "nothing"
#   type        = "String"
#   value       = "random() is always 4"
# }

resource "aws_ssm_parameter" "secret2" {
  name        = "/api/charla2"
  description = "nothing"
  type        = "String"
  value       = "random() is always 5"
}