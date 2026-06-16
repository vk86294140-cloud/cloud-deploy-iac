output "service_url" {
  description = "Public URL of the deployed service (via the ALB)."
  value       = "http://${aws_lb.this.dns_name}"
}

output "ecr_repository_url" {
  description = "Push images here; CI tags them with the git SHA."
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "autoscaling_capacity" {
  description = "Task-count bounds Application Auto Scaling holds the service within."
  value       = "${var.min_capacity}..${var.max_capacity} tasks"
}

output "dashboard_url" {
  description = "CloudWatch dashboard."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
