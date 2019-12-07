output "sns_topic_arn" {
  value = "${aws_sns_topic.import_data_topic.arn}"
}
