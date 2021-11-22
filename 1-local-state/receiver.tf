resource "aws_sqs_queue" "queue" {
  for_each                  = local.channels
  name                      = "my-sqs-queue-${each.key}"
  delay_seconds             = 0              // how long to delay delivery of records
  max_message_size          = 262144         // = 256KiB, which is the limit set by AWS
  message_retention_seconds = 86400          // = 1 day in seconds
  receive_wait_time_seconds = 10             // how long to wait for a record to stream in when ReceiveMessage is called
  tags                              = {}
}

resource "aws_iam_role" "api" {
  for_each                  = local.channels
  name                      = "my-api-role-${each.key}"

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
  for_each                  = local.channels
  name                      = "my-api-perms-${each.key}"
  tags      = {}

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
        "Resource": "${aws_sqs_queue.queue[each.key].arn}"
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
  for_each                  = local.channels
  rest_api_id           = "${aws_api_gateway_rest_api.api.id}"
  name                  = "payload-validator-${each.key}"
  validate_request_body = true
}

resource "aws_api_gateway_model" "api" {
  for_each                  = local.channels
  name                      = "PayloadValidator${each.key}"
  rest_api_id  = "${aws_api_gateway_rest_api.api.id}"
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
  for_each                  = local.channels
  role       = "${aws_iam_role.api[each.key].name}"
  policy_arn = "${aws_iam_policy.api[each.key].arn}"
}


resource "aws_api_gateway_resource" "api" {
  for_each                  = local.channels
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "api" {
  for_each                  = local.channels
  rest_api_id          = "${aws_api_gateway_rest_api.api.id}"
  resource_id          = "${aws_api_gateway_resource.api[each.key].id}"
  api_key_required     = false
  http_method          = "POST"
  authorization        = "NONE"
  request_validator_id = "${aws_api_gateway_request_validator.api[each.key].id}"
  request_parameters   = {}
  authorization_scopes = []


  request_models = {
    "application/json" = "${aws_api_gateway_model.api[each.key].name}"
  }
}

resource "aws_api_gateway_integration" "api" {
  for_each                  = local.channels
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.api[each.key].id}"
  http_method             = "POST"
  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
  cache_key_parameters    = []
  credentials             = "${aws_iam_role.api[each.key].arn}"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${aws_sqs_queue.queue[each.key].name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }

  depends_on = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api, aws_api_gateway_method.api] 
}

resource "aws_api_gateway_integration_response" "two" {
  for_each                  = local.channels
  rest_api_id       = "${aws_api_gateway_rest_api.api.id}"
  resource_id       = "${aws_api_gateway_resource.api[each.key].id}"
  http_method       = "${aws_api_gateway_method.api[each.key].http_method}"
  status_code       = "${aws_api_gateway_method_response.two[each.key].status_code}"
  selection_pattern = "^2[0-9][0-9]"                                       // regex pattern for any 200 message that comes back from SQS
  response_parameters = {}

  response_templates = {
    "application/json" = "{\"message\": \"great success!\"}"
  }

  depends_on = [aws_api_gateway_integration.api, aws_api_gateway_method.api, aws_api_gateway_method_response.two]
}

resource "aws_api_gateway_method_response" "two" {
  for_each                  = local.channels
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.api[each.key].id}"
  http_method = "${aws_api_gateway_method.api[each.key].http_method}"
  status_code = 200
  response_parameters = {}

  response_models = {
    "application/json" = "Empty"
  }
}