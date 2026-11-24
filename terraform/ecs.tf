data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_ecs_cluster" "moodle" {
  name = var.name

  tags = {
    Name = var.name
  }
}

resource "aws_ecs_task_definition" "moodle" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = "${aws_ecr_repository.moodle.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.moodle.address },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_username },
        { name = "DB_PASS", value = random_password.db.result },
        { name = "ADMIN_PASS", value = random_password.admin.result },
        { name = "ADMIN_EMAIL", value = var.admin_email },
        { name = "MOODLE_FULLNAME", value = var.moodle_fullname },
        { name = "MOODLE_SHORTNAME", value = var.moodle_shortname },
        { name = "MOODLE_WWWROOT", value = "auto" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.moodle.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "moodle"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -fsS http://localhost/healthz.php >/dev/null || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 10
        startPeriod = 300
      }
    }
  ])
}

resource "aws_ecs_service" "moodle" {
  name            = var.name
  cluster         = aws_ecs_cluster.moodle.id
  task_definition = aws_ecs_task_definition.moodle.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = var.name
  }
}
