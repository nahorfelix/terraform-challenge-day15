provider "docker" {}

# Pull the nginx image from Docker Hub
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Run an nginx container exposed on localhost:8080
resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "terraform-nginx"
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 8090
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }

  labels {
    label = "challenge"
    value = "day15"
  }
}
