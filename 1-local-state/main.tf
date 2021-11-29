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
  tags        = {}
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"

  depends_on = [
    aws_api_gateway_integration.api,
    aws_api_gateway_integration_response.two
  ]

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
  # cache_cluster_size = 0.5
  tags = {}
  variables = {}
}

resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_usage_plan" "main" {
  name         = "my-usage-plan"
  description  = "my description"
  product_code = "MYCODE"
  tags = {}

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.main.stage_name
  }
}

resource "aws_api_gateway_api_key" "mykey" {
  name = "my_key"
  tags = {}
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
  tags = {}
}


output "test_cURL" {
  value = <<EOF
API_KEY=$(aws ssm get-parameter --name "/api/api_key" --with-decryption --query "Parameter.Value" --output text)
%{ for channel in local.channels }
curl -X POST -H 'Content-Type: application/json' -H "X-API-KEY: $API_KEY"  -d '{"id":"test", "docs":[{"key":"value"}]}' ${aws_api_gateway_stage.main.invoke_url}/${channel}
%{ endfor }
EOF
}