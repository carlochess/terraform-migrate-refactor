# "aws_api_gateway_rest_api.api.id" {
variable "api_id" {}
# "aws_api_gateway_rest_api.api.root_resource_id"
variable "api_root_resource_id" {}
# "aws_api_gateway_request_validator.api.id"
variable "api_request_validator_api_id" {}
# "aws_api_gateway_model.api.name"
variable "api_model_api_name" {}
# "aws_iam_role.api.arn"
variable "role_api_arn" {}
# "aws_sqs_queue.queue.name"
variable "queue_name" {}


variable "region" {
  default = "us-east-1"
  type    = string
}