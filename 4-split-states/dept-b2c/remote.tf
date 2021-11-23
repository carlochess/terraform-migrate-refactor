terraform {
  required_version = ">= 0.12"

  backend "s3" {
    key            = "charla4b2c.tfstate"
    bucket         = "charla-tf-state"
    region         = "us-east-1"
    profile        = "charla"
    dynamodb_table = "charla-tf-state"
  }
}