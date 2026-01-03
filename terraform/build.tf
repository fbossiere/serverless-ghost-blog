resource "null_resource" "docker_push" {
  triggers = {
    # Trigger on Dockerfile changes to rebuild only when needed
    dockerfile_sha1 = filesha1("${path.module}/../Dockerfile")
    registry_endpoint = scaleway_registry_namespace.main.endpoint
  }

  provisioner "local-exec" {
    command = <<EOT
      set -e
      echo "Logging into Scaleway Registry..."
      echo "$SCW_SECRET_KEY" | docker login ${scaleway_registry_namespace.main.endpoint} -u nologin --password-stdin
      echo "Building Docker image..."
      docker build --platform linux/amd64 -t ${scaleway_registry_namespace.main.endpoint}/ghost-s3:latest ${path.module}/..
      echo "Pushing Docker image..."
      docker push ${scaleway_registry_namespace.main.endpoint}/ghost-s3:latest
    EOT
    
    interpreter = ["/bin/bash", "-c"]
    
    environment = {
      SCW_SECRET_KEY = var.scw_secret_key # We need to pass this variable
    }
  }
  
  depends_on = [scaleway_registry_namespace.main]
}
