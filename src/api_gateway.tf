resource "aws_api_gateway_rest_api" "spotifydb_api" {
  name        = "SpotifyDBAPI"
  description = "API Gateway for SpotifyDB"
}
resource "aws_api_gateway_resource" "playlist_tracks_api_gw_resource" {
  path_part   = "playlist"
  parent_id   = aws_api_gateway_rest_api.spotifydb_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_method" "playlist_tracks_api_gw_method" {
  rest_api_id   = aws_api_gateway_rest_api.spotifydb_api.id
  resource_id   = aws_api_gateway_resource.playlist_tracks_api_gw_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "playlist_tracks_integration" {
  rest_api_id             = aws_api_gateway_rest_api.spotifydb_api.id
  resource_id             = aws_api_gateway_resource.playlist_tracks_api_gw_resource.id
  http_method             = aws_api_gateway_method.playlist_tracks_api_gw_method.http_method
  integration_http_method = "POST" # Lambdas can only be invoked with POST
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.playlist_api_lambda.invoke_arn
}

# Lambda
resource "aws_lambda_permission" "api_gw_playlist_tracks_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.playlist_api_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.identity.account_id}:${aws_api_gateway_rest_api.spotifydb_api.id}/*/${aws_api_gateway_method.playlist_tracks_api_gw_method.http_method}${aws_api_gateway_resource.playlist_tracks_api_gw_resource.path}"
}