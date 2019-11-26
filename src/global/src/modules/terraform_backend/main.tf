resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = "${var.enable_versioning}"
  }
}

data "aws_iam_policy_document" "bucket_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
    principals {
      type        = "AWS"
      identifiers = ["${var.terraform_arn}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${var.terraform_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.aws_iam_policy_document.bucket_policy_document.json}"
}
