resource "aws_s3_bucket" "remote_state_bucket" {
  bucket = var.remote_state_bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}

data "aws_iam_policy_document" "remote_state_bucket_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.remote_state_bucket_name}"]
    principals {
      type        = "AWS"
      identifiers = [var.terraform_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.remote_state_bucket_name}/*"]
    principals {
      type        = "AWS"
      identifiers = [var.terraform_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "remote_state_bucket_policy_document" {
  bucket = aws_s3_bucket.remote_state_bucket.id
  policy = data.aws_iam_policy_document.remote_state_bucket_policy_document.json
}
