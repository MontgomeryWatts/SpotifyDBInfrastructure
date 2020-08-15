resource "aws_ecr_repository" "spotify_sampler_repository" {
  name = "spotify_sampler_repository"
}

resource "aws_ecs_cluster" "spotify_sampler_cluster" {
  name = "spotify_sampler_cluster"
}

resource "aws_ecs_service" "sampler_web_server_service" {
  name            = "spotify_sampler_service"
  cluster         = aws_ecs_cluster.spotify_sampler_cluster.id
  task_definition = aws_ecs_task_definition.spotify_sampler_task_definition.arn
  desired_count   = 1
  network_configuration {
    subnets = aws_subnet.container_subnet[*].id
    security_groups = [aws_security_group.container_sg.id]
  }
}

data "template_file" "task_definition_template" {
  template = file("task-definitions/service.json.tpl")
  vars = {
    mongodb_uri        = var.mongodb_uri
    aws_ecr_repository = aws_ecr_repository.spotify_sampler_repository.name
    tag                = "latest"
  }
}

resource "aws_ecs_task_definition" "spotify_sampler_task_definition" {
  family                   = "spotify_sampler_web_server"
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.task_definition_template.rendered
}