resource "aws_s3_bucket" "main_bucket" {
  bucket = "${var.url}"
  acl    = "public-read"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket" "www_bucket" {
  bucket = "www.${var.url}"

  website {
    redirect_all_requests_to = "${var.url}"
  }
}

data "aws_iam_policy_document" "bucket_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.url}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}


resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.main_bucket.id}"
  policy = "${data.aws_iam_policy_document.bucket_policy_document.json}"
}
