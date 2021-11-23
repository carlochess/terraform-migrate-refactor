provider "aws" {
  region = "${var.region}"
}

variable "region" {
  default = "us-east-1"
  type    = string
}

locals {
  channels = toset(["b2b", "b2c", "others"])
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "my-sqs-api"
  description = "POST records to SQS queue"
}

module "apigatewayresource" {
  source  = "./api-gateway-resource"
  for_each                  = local.channels

  api_id = aws_api_gateway_rest_api.api.id
  api_root_resource_id = aws_api_gateway_rest_api.api.root_resource_id
  name     = "${each.key}"
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"

  #depends_on = [
  #  aws_api_gateway_integration.api,
  #]

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "main"
}


resource "aws_api_gateway_usage_plan" "main" {
  name         = "my-usage-plan"
  description  = "my description"
  product_code = "MYCODE"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.main.stage_name
  }
}

resource "aws_api_gateway_api_key" "mykey" {
  name = "my_key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.mykey.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}

resource "aws_ssm_parameter" "secret" {
  name        = "/api/api_key"
  description = "API header"
  type        = "SecureString"
  value       = aws_api_gateway_api_key.mykey.value
}

output "test_cURL" {
  value = <<EOF
API_KEY=$(aws ssm get-parameter --name "/api/api_key" --with-decryption --query "Parameter.Value" --output text)
%{ for channel in local.channels }
curl -X POST -H 'Content-Type: application/json' -H "X-API-KEY: $API_KEY"  -d '{"id":"test", "docs":[{"key":"value"}]}' ${aws_api_gateway_stage.main.invoke_url}/${channel}
%{ endfor }
EOF
}