# Application Auto Scaling for the ECS service.
#
# monitoring.tf raises an alarm when CPU stays hot; this keeps it from staying
# hot in the first place by scaling the task count between min_capacity and
# max_capacity. Two target-tracking policies run together — AWS scales to satisfy
# whichever demands more tasks:
#   1. average ECS CPU utilization, and
#   2. ALB requests per running task (catches load spikes before CPU even moves).

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-cpu-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_utilization
    scale_out_cooldown = 60
    scale_in_cooldown  = 120
  }
}

resource "aws_appautoscaling_policy" "requests" {
  name               = "${var.project_name}-alb-requests-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      # ResourceLabel ties the metric to this LB + target group:
      # <lb-arn-suffix>/<target-group-arn-suffix>.
      resource_label = "${aws_lb.this.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
    target_value       = var.requests_per_target
    scale_out_cooldown = 60
    scale_in_cooldown  = 120
  }
}
