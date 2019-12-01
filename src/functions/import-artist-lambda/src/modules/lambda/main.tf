resource "aws_lambda_function" "spotifydb_import_artist_lambda" {
  filename      = "CHANGEME"
  function_name = "spotifydb-import-artist"
  handler       = "CHANGEME"
  runtime       = "java8"
  role          = "${aws_iam_role.lambda_role.arn}"
  timeout       = "5"

  environment {
    variables {
      SPOTIFY_CLIENT_ID     = "${var.client_id}"
      SPOTIFY_CLIENT_SECRET = "${var.client_secret}"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "spotifydb-import-artist-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

  }
}
