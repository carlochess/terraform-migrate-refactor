
locals {
  channels = toset(["b2b", "b2c", "others"])
}


module "apigatewayresource" {
  source  = "./api-gateway-resource"
  for_each                  = local.channels

  api_id = aws_api_gateway_rest_api.api.id
  api_root_resource_id = aws_api_gateway_rest_api.api.root_resource_id
  name     = "${each.key}"
}

output "test_cURL" {
  value = <<EOF
API_KEY=$(aws ssm get-parameter --name "/api/api_key" --with-decryption --query "Parameter.Value")
%{ for channel in local.channels }
curl -X POST -H 'Content-Type: application/json' -H "X-API-KEY: $API_KEY"  -d '{"id":"test", "docs":[{"key":"value"}]}' ${aws_api_gateway_stage.main.invoke_url}/${channel}
%{ endfor }
EOF
}