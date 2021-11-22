# "aws_api_gateway_rest_api.api.id" {
variable "api_id" {}
# "aws_api_gateway_rest_api.api.root_resource_id"
variable "api_root_resource_id" {}
variable "name" {}


variable "region" {
  default = "us-east-1"
  type    = string
}