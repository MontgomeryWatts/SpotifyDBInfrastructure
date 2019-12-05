output "lambda_arns" {
  value = ["${module.import-album-lambda.lambda_arn}", "${module.import-artist-lambda.lambda_arn}"]
}
