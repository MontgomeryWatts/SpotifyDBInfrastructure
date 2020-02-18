output "playlist_transform_lambda_role_arn" {
  value = "${aws_iam_role.transform_lambda_role.arn}"
}
