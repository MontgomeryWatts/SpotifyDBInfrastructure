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
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.container_subnet[*].id
    security_groups  = [aws_security_group.container_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_server_target_group.arn
    container_name   = "web-server"
    container_port   = 80
  }
}

resource "aws_cloudwatch_log_group" "ecs_task_log_group" {
  name = "spotify-sampler-log-group"
}

resource "aws_ecs_task_definition" "spotify_sampler_task_definition" {
  family                   = "spotify_sampler_web_server"
  network_mode             = "awsvpc"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.identity.account_id}:role/ecsTaskExecutionRole"
  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "name": "web-server",
      "image": "${aws_ecr_repository.spotify_sampler_repository.repository_url}:latest",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "web-server",
          "awslogs-group": "${aws_cloudwatch_log_group.ecs_task_log_group.name}"
        }
      },
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        },
        {
          "containerPort": 443,
          "protocol": "tcp"
        },
        {
          "containerPort": 27015,
          "protocol": "tcp"
        },
        {
          "containerPort": 27016,
          "protocol": "tcp"
        },
        {
          "containerPort": 27017,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "MONGODB_URI",
          "value": "${var.mongodb_uri}"
        },
        {
          "name": "PORT",
          "value": "80"
        }
      ]
    }
]
TASK_DEFINITION
}