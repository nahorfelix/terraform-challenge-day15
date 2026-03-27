variable "app_name" {
  description = "Application name prefix for all resources"
  type        = string
  default     = "day15-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
