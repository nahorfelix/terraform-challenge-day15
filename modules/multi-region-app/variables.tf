variable "app_name" {
  description = "Application name — used as a prefix for all bucket names"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}
