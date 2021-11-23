# data "terraform_remote_state" "vpc" {
#   backend = "local"
#   config = {
#     path = "..."
#   }
# }

data "aws_api_gateway_rest_api" "api" {
  name = "my-sqs-api"
}

locals {
  channel = "others"
}

module "apigatewayresource" {
  source  = "./api-gateway-resource"

  api_id = data.aws_api_gateway_rest_api.api.id
  api_root_resource_id = data.aws_api_gateway_rest_api.api.root_resource_id
  name     = "${local.channel}"
}

# output "test_cURL" {
#   value = <<EOF
# API_KEY=$(aws ssm get-parameter --name "/api/api_key" --with-decryption --query "Parameter.Value")
# curl -X POST -H 'Content-Type: application/json' -H "X-API-KEY: $API_KEY"  -d '{"id":"test", "docs":[{"key":"value"}]}' ${data.aws_api_gateway_stage.main.invoke_url}/${local.channel}
# EOF
# }