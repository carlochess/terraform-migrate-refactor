# resource "aws_sqs_queue" "queue" {
#   name                      = "my-sqs-queue-${var.name}"
#   delay_seconds             = 0              // how long to delay delivery of records
#   max_message_size          = 262144         // = 256KiB, which is the limit set by AWS
#   message_retention_seconds = 86400          // = 1 day in seconds
#   receive_wait_time_seconds = 10             // how long to wait for a record to stream in when ReceiveMessage is called
# }
// ...
resource "aws_ssm_parameter" "secret" {
  name        = "/api/charla"
  description = "nothing"
  type        = "String"
  value       = "random() is always 4"
}