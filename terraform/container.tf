resource "scaleway_container" "ghost" {
  name            = var.app_name
  namespace_id    = scaleway_container_namespace.main.id
  registry_image  = "${scaleway_registry_namespace.main.endpoint}/ghost-s3:latest"
  port            = 2368
  cpu_limit       = 1000
  memory_limit    = 1024
  min_scale       = 1
  max_scale       = 5
  timeout         = 600
  deploy          = true

  private_network_id = scaleway_vpc_private_network.main.id

  environment_variables = {
    "NODE_ENV"                       = "production"
    "security__staffDeviceVerification" = "false"
    "url"                            = var.custom_domain != "" ? "https://${var.custom_domain}" : "https://${var.app_name}-${scaleway_container_namespace.main.id}.functions.fnc.${var.region}.scw.cloud"
    "admin__url"                     = var.custom_domain != "" ? "https://${var.custom_domain}" : "https://${var.app_name}-${scaleway_container_namespace.main.id}.functions.fnc.${var.region}.scw.cloud"
    "database__client"               = "mysql"
    "database__connection__host"     = scaleway_rdb_instance.main.private_network[0].ip
    "database__connection__port"     = tostring(scaleway_rdb_instance.main.private_network[0].port)
    "database__connection__user"     = scaleway_rdb_user.ghost.name
    "database__connection__database" = scaleway_rdb_database.ghost.name
    
    "storage__active"                = "s3"
    "storage__s3__region"            = var.region
    "storage__s3__bucket"            = scaleway_object_bucket.content.name
    "storage__s3__endpoint"          = "https://s3.${var.region}.scw.cloud"
    "storage__s3__forcePathStyle"    = "true"
    "storage__s3__signatureVersion"  = "v4"
    "storage__s3__assetHost"         = "https://${scaleway_object_bucket.content.name}.s3.${var.region}.scw.cloud"
    
    "logging__level"                 = "debug"
    
    "mail__from"                 = "\"${var.mail_from_name}\" <${var.mail_from_email}>"
    "mail__transport"            = "SMTP"
    "mail__options__host"        = var.mail_smtp_host
    "mail__options__port"        = var.mail_smtp_port
    "mail__options__secure"      = var.mail_smtp_secure
    "mail__options__auth__user"  = var.mail_smtp_user

    "activitypub__enabled"           = "false"
    "session__secure"                = "true"
    "session__sameSite"              = "Lax"
    "session__trust_proxy"           = "true"
    "session__path"                  = "/"
    "caching__query__max"            = "1000"
    "caching__query__ttl"            = "60"
  }

  secret_environment_variables = {
    "database__connection__password" = local.db_app_password
    "storage__s3__accessKeyId"       = scaleway_iam_api_key.ghost_s3_key.access_key
    "storage__s3__secretAccessKey"   = scaleway_iam_api_key.ghost_s3_key.secret_key
    "mail__options__auth__pass"      = base64decode(scaleway_secret_version.smtp_password.data)
  }
  
  # Ensure DB, Bucket exist and Image is pushed before deploying container
  depends_on = [
    scaleway_rdb_database.ghost,
    scaleway_rdb_user.ghost,
    scaleway_rdb_privilege.ghost_access,
    scaleway_object_bucket.content,
    scaleway_iam_policy.ghost_s3_policy,
    scaleway_secret_version.smtp_password,
    null_resource.docker_push
  ]
}

resource "scaleway_container_domain" "main" {
  count        = var.custom_domain != "" ? 1 : 0
  container_id = scaleway_container.ghost.id
  hostname     = var.custom_domain
}
