# ---------------------------------------------------------------------------
# Resources created by this project (bwtest- prefix, us-east-1).
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "orders" {
  bucket = var.bucket_name
}

resource "aws_sqs_queue" "orders" {
  name = "bwtest-orders-queue"
}

resource "aws_sns_topic" "orders" {
  name = "bwtest-orders-topic"
}

resource "aws_dynamodb_table" "orders" {
  name         = "bwtest-orders-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }
}

# ---------------------------------------------------------------------------
# NOT ours: existing Terraform lock table. Described here only, adopted by
# import. prevent_destroy guards it against accidental deletion.
# ---------------------------------------------------------------------------

import {
  to = aws_dynamodb_table.terraform_locks
  id = "brightcone-terraform-locks"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "brightcone-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# NOT ours: the EC2 instance hosting this server. Described here only, adopted
# by import. ignore_changes = all means apply never modifies it.
# ---------------------------------------------------------------------------

import {
  to = aws_instance.server
  id = "i-0e029fa5e9c18ed2a"
}

resource "aws_instance" "server" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t3.medium"
  subnet_id              = "subnet-0c1cef0e1b2aef3f4"
  vpc_security_group_ids = ["sg-00ac3c9f299173849"]
  key_name               = "bw-aws-infra-test-1793706771"

  tags = {
    Name = "bw-aws-infra-test"
  }

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}
