resource "aws_s3_bucket" "datalake_bucket" {
  bucket = var.datalake_bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "datalake_bucket_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.datalake_bucket_name}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.import_entity_lambda_role.arn]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.datalake_bucket_name}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.playlist_transform_lambda_role.arn]
    }
  }
}


resource "aws_s3_bucket_policy" "datalake_bucket_policy" {
  bucket = aws_s3_bucket.datalake_bucket.id
  policy = data.aws_iam_policy_document.datalake_bucket_policy_document.json
}

resource "aws_sns_topic" "spotify_data_topic" {
  name = "spotify-data-topic"
}

data "aws_iam_policy_document" "datalake_sns_topic_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.spotify_data_topic.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.datalake_bucket.arn]
    }
  }
}

resource "aws_sns_topic_policy" "datalake_sns_topic_policy" {
  arn    = aws_sns_topic.spotify_data_topic.arn
  policy = data.aws_iam_policy_document.datalake_sns_topic_policy_document.json
}

resource "aws_s3_bucket_notification" "datalake_bucket_notification" {
  bucket = aws_s3_bucket.datalake_bucket.id

  topic {
    topic_arn = aws_sns_topic.spotify_data_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}
