provider "aws" {
  version = "1.1.0"
  region  = "eu-west-1"
}

resource "aws_iam_user" "main" {
  name = "concourse-terraform-task-test"
  force_destroy = "true"
}
