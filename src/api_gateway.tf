resource "aws_api_gateway_rest_api" "spotifydb_api" {
  name        = "SpotifyDBAPI"
  description = "API Gateway for SpotifyDB"
}

resource "aws_api_gateway_deployment" "spotifydb_deployment" {
  stage_name  = "prod"
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "root_resource" {
  path_part   = "api"
  parent_id   = aws_api_gateway_rest_api.spotifydb_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "albums_resource" {
  path_part   = "albums"
  parent_id   = aws_api_gateway_resource.root_resource.id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "artists_resource" {
  path_part   = "artists"
  parent_id   = aws_api_gateway_resource.root_resource.id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "random_artists_resource" {
  path_part   = "random"
  parent_id   = aws_api_gateway_resource.artists_resource.id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_method" "random_artists_method" {
  rest_api_id   = aws_api_gateway_rest_api.spotifydb_api.id
  resource_id   = aws_api_gateway_resource.random_artists_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "random_artists_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.spotifydb_api.id
  resource_id             = aws_api_gateway_resource.random_artists_resource.id
  http_method             = aws_api_gateway_method.random_artists_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.random_artist_lambda.invoke_arn
}

resource "aws_lambda_permission" "random_artists_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.random_artist_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.identity.account_id}:${aws_api_gateway_rest_api.spotifydb_api.id}/*/${aws_api_gateway_method.random_artists_method.http_method}${aws_api_gateway_resource.random_artists_resource.path}"
}