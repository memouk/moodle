resource "aws_cloudwatch_log_group" "moodle" {
  name              = "/ecs/${var.name}"
  retention_in_days = 1

  tags = {
    Name = var.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.name}-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU de la tarea de Moodle por encima del 80 por ciento."
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.moodle.name
    ServiceName = aws_ecs_service.moodle.name
  }

  tags = {
    Name = var.name
  }
}
