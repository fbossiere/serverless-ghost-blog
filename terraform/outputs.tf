output "registry_endpoint" {
  value = scaleway_registry_namespace.main.endpoint
  description = "The endpoint of the Container Registry. Push your image here."
}

output "registry_login_command" {
  value = "docker login ${scaleway_registry_namespace.main.endpoint} -u nologin --password-stdin <<< \"$SCW_SECRET_KEY\""
  description = "Command to login to the registry"
}

output "image_push_command" {
  value = "docker build -t ${scaleway_registry_namespace.main.endpoint}/ghost-s3:latest .. && docker push ${scaleway_registry_namespace.main.endpoint}/ghost-s3:latest"
  description = "Command to build and push the image"
}

output "container_url" {
  value = scaleway_container.ghost.domain_name
  description = "The URL of the deployed Ghost container"
}

output "db_endpoint" {
  value = "${scaleway_rdb_instance.main.private_network[0].ip}:${scaleway_rdb_instance.main.private_network[0].port}"
}

output "bucket_name" {
  value = scaleway_object_bucket.content.name
}

output "bucket_endpoint" {
  value = "https://${scaleway_object_bucket.content.name}.s3.${var.region}.scw.cloud"
  description = "The S3 endpoint for the bucket"
}

output "secret_ids" {
  value = {
    db_password   = scaleway_secret.db_password.id
    s3_access_key = scaleway_secret.s3_access_key.id
    s3_secret_key = scaleway_secret.s3_secret_key.id
    smtp_password = scaleway_secret.smtp_password.id
  }
  description = "IDs of the secrets stored in Scaleway Secret Manager"
}

output "dns_configuration" {
  value = var.custom_domain != "" ? {
    domain = var.custom_domain
    type   = "CNAME"
    name   = split(".", var.custom_domain)[0] # e.g., "blog" from "blog.example.com"
    value  = scaleway_container.ghost.domain_name
    instructions = "Add a CNAME record: ${split(".", var.custom_domain)[0]} -> ${scaleway_container.ghost.domain_name}"
  } : null
  description = "DNS configuration needed for custom domain"
}
