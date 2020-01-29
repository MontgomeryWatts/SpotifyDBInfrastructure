resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "bucket_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    principals {
      type        = "AWS"
      identifiers = "${var.import_lambda_role_arns}"
    }
  }
}


resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.aws_iam_policy_document.bucket_policy_document.json}"
}

resource "aws_sns_topic" "spotify_data_topic" {
  name = "spotify-data-topic"
}

data "aws_iam_policy_document" "topic_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.spotify_data_topic.arn}"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["${aws_s3_bucket.bucket.arn}"]
    }
  }
}

resource "aws_sns_topic_policy" "topic_policy" {
  arn    = "${aws_sns_topic.spotify_data_topic.arn}"
  policy = "${data.aws_iam_policy_document.topic_policy_document.json}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.bucket.id}"

  topic {
    topic_arn = "${aws_sns_topic.spotify_data_topic.arn}"
    events    = ["s3:ObjectCreated:*"]
  }
}
