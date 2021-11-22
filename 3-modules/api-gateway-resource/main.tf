
###############

resource "aws_api_gateway_resource" "api" {
  rest_api_id = var.api_id
  parent_id   = var.api_root_resource_id
  path_part   = "sqs1"
}

resource "aws_api_gateway_method" "api" {
  rest_api_id          = "${var.api_id}"
  resource_id          = "${aws_api_gateway_resource.api.id}"
  api_key_required     = false
  http_method          = "POST"
  authorization        = "NONE"
  request_validator_id = "${var.api_request_validator_api_id}"

  request_models = {
    "application/json" = "${var.api_model_api_name}"
  }
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id             = "${var.api_id}"
  resource_id             = "${aws_api_gateway_resource.api.id}"
  http_method             = "POST"
  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
  cache_key_parameters    = []
  credentials             = "${var.role_api_arn}"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${var.queue_name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }

  # depends_on = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api]
  depends_on = [aws_api_gateway_resource.api]
}

resource "aws_api_gateway_integration_response" "two" {
  rest_api_id       = "${var.api_id}"
  resource_id       = "${aws_api_gateway_resource.api.id}"
  http_method       = "${aws_api_gateway_method.api.http_method}"
  status_code       = "${aws_api_gateway_method_response.two.status_code}"
  selection_pattern = "^2[0-9][0-9]"                                       // regex pattern for any 200 message that comes back from SQS
  response_parameters = {}

  response_templates = {
    "application/json" = "{\"message\": \"great success!\"}"
  }

  depends_on = [aws_api_gateway_integration.api, aws_api_gateway_method.api]
}

resource "aws_api_gateway_method_response" "two" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource.api.id}"
  http_method = "${aws_api_gateway_method.api.http_method}"
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }
}

###############

resource "aws_api_gateway_resource" "api2" {
  rest_api_id = var.api_id
  parent_id   = var.api_root_resource_id
  path_part   = "sqs2"
}

resource "aws_api_gateway_method" "api2" {
  rest_api_id          = "${var.api_id}"
  resource_id          = "${aws_api_gateway_resource.api2.id}"
  api_key_required     = false
  http_method          = "POST"
  authorization        = "NONE"
  request_validator_id = "${var.api_request_validator_api_id}"

  request_models = {
    "application/json" = "${var.api_model_api_name}"
  }
}

resource "aws_api_gateway_integration" "api2" {
  rest_api_id             = "${var.api_id}"
  resource_id             = "${aws_api_gateway_resource.api2.id}"
  http_method             = "POST"
  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
  credentials             = "${var.role_api_arn}"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${var.queue_name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }

  # depends_on = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api]
  depends_on = [aws_api_gateway_resource.api2]
}

resource "aws_api_gateway_integration_response" "two2" {
  rest_api_id       = "${var.api_id}"
  resource_id       = "${aws_api_gateway_resource.api2.id}"
  http_method       = "${aws_api_gateway_method.api2.http_method}"
  status_code       = "${aws_api_gateway_method_response.two2.status_code}"
  selection_pattern = "^2[0-9][0-9]"                                       // regex pattern for any 200 message that comes back from SQS
  response_parameters = {}

  response_templates = {
    "application/json" = "{\"message\": \"great success!\"}"
  }

  depends_on = [aws_api_gateway_integration.api, aws_api_gateway_method.api2]
}

resource "aws_api_gateway_method_response" "two2" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource.api2.id}"
  http_method = "${aws_api_gateway_method.api2.http_method}"
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }
}
