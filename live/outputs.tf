output "primary_bucket_id" {
  description = "Primary bucket name (us-east-1)"
  value       = module.multi_region_app.primary_bucket_id
}

output "primary_bucket_arn" {
  description = "Primary bucket ARN"
  value       = module.multi_region_app.primary_bucket_arn
}

output "replica_bucket_id" {
  description = "Replica bucket name (us-west-2)"
  value       = module.multi_region_app.replica_bucket_id
}

output "replica_bucket_arn" {
  description = "Replica bucket ARN"
  value       = module.multi_region_app.replica_bucket_arn
}
