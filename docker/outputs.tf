output "container_name" {
  description = "Name of the running nginx container"
  value       = docker_container.nginx.name
}

output "container_id" {
  description = "Full container ID"
  value       = docker_container.nginx.id
}

output "nginx_url" {
  description = "URL to access the nginx container"
  value       = "http://localhost:8090"
}

output "image_id" {
  description = "Docker image ID used by the container"
  value       = docker_image.nginx.image_id
}
