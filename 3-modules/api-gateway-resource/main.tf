resource "aws_sqs_queue" "queue" {
  name                      = "my-sqs-queue-${var.name}"
  delay_seconds             = 0              // how long to delay delivery of records
  max_message_size          = 262144         // = 256KiB, which is the limit set by AWS
  message_retention_seconds = 86400          // = 1 day in seconds
  receive_wait_time_seconds = 10             // how long to wait for a record to stream in when ReceiveMessage is called
}

resource "aws_iam_role" "api" {
  name                      = "my-api-role-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "api" {
  name                      = "my-api-perms-${var.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility",
          "sqs:ListDeadLetterSourceQueues",
          "sqs:SendMessageBatch",
          "sqs:PurgeQueue",
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:ListQueueTags",
          "sqs:ChangeMessageVisibilityBatch",
          "sqs:SetQueueAttributes"
        ],
        "Resource": "${aws_sqs_queue.queue.arn}"
      },
      {
        "Effect": "Allow",
        "Action": "sqs:ListQueues",
        "Resource": "*"
      }
    ]
}
EOF
}

resource "aws_api_gateway_request_validator" "api" {
  rest_api_id           = "${var.api_id}"
  name                  = "payload-validator-${var.name}"
  validate_request_body = true
}

resource "aws_api_gateway_model" "api" {
  name                      = "PayloadValidator${var.name}"
  rest_api_id  = "${var.api_id}"
  description  = "validate the json body content conforms to the below spec"
  content_type = "application/json"

  schema = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "required": [ "id", "docs"],
  "properties": {
    "id": { "type": "string" },
    "docs": {
      "minItems": 1,
      "type": "array",
      "items": {
        "type": "object"
      }
    }
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "api" {
  role       = "${aws_iam_role.api.name}"
  policy_arn = "${aws_iam_policy.api.arn}"
}


resource "aws_api_gateway_resource" "api" {
  rest_api_id = var.api_id
  parent_id   = var.api_root_resource_id
  path_part   = var.name
}

resource "aws_api_gateway_method" "api" {
  rest_api_id          = "${var.api_id}"
  resource_id          = "${aws_api_gateway_resource.api.id}"
  api_key_required     = true
  http_method          = "POST"
  authorization        = "NONE"
  request_validator_id = "${aws_api_gateway_request_validator.api.id}"

  request_models = {
    "application/json" = "${aws_api_gateway_model.api.name}"
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
  credentials             = "${aws_iam_role.api.arn}"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${aws_sqs_queue.queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }

  # depends_on = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api, aws_api_gateway_method.api] 
  depends_on = [aws_api_gateway_resource.api, aws_api_gateway_method.api] 
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

  depends_on = [aws_api_gateway_integration.api, aws_api_gateway_method.api, aws_api_gateway_method_response.two]
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