resource "aws_sns_topic" "import_data_topic" {
  name = "import-data-topic"
}

data "aws_iam_policy_document" "topic_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.import_data_topic.arn}"]
    principals {
      type        = "AWS"
      identifiers = "${var.fan_out_lambda_role_arns}"
    }
  }
}

resource "aws_sns_topic_policy" "topic_policy" {
  arn    = "${aws_sns_topic.import_data_topic.arn}"
  policy = "${data.aws_iam_policy_document.topic_policy_document.json}"
}