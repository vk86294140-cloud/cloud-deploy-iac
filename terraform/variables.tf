variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all created resources."
  type        = string
  default     = "cloud-deploy-iac"
}

variable "container_image" {
  description = "Full image URI to deploy (e.g. <acct>.dkr.ecr.<region>.amazonaws.com/cloud-deploy-iac:<tag>). Defaults to the ECR repo created here at the :latest tag."
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8000
}

variable "desired_count" {
  description = "Initial number of Fargate tasks to run (autoscaling drives it after start)."
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum Fargate task count Application Auto Scaling will hold."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum Fargate task count Application Auto Scaling may scale out to."
  type        = number
  default     = 6
}

variable "cpu_target_utilization" {
  description = "Target average ECS CPU percent for the scaling policy."
  type        = number
  default     = 70
}

variable "requests_per_target" {
  description = "Target ALB requests-per-task for the request-based scaling policy."
  type        = number
  default     = 1000
}

variable "cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "HTTP path the ALB uses for health checks."
  type        = string
  default     = "/health"
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 14
}

variable "alarm_email" {
  description = "Optional email to receive CloudWatch alarm notifications. Leave empty to skip SNS subscription."
  type        = string
  default     = ""
}
