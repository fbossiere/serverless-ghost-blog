provider "scaleway" {
  organization_id = var.organization_id
  project_id      = var.project_id
  region          = var.region
  zone            = var.zone
}

resource "random_password" "db_admin_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
}

resource "random_password" "db_app_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
}

locals {
  db_admin_password = random_password.db_admin_password.result
  db_app_password   = var.db_password != "" ? var.db_password : random_password.db_app_password.result
}

# --- Container Registry ---
resource "scaleway_registry_namespace" "main" {
  name        = "${var.project_name}-registry"
  description = "Registry for ${var.project_name}"
  is_public   = false
}

# --- Object Storage (S3) ---
resource "scaleway_object_bucket" "content" {
  name = "${var.app_name}-${var.project_name}-v2"
  
  cors_rule {
    allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    allowed_origins = [
      "https://${var.custom_domain != "" ? var.custom_domain : "${var.app_name}-${scaleway_container_namespace.main.id}.functions.fnc.${var.region}.scw.cloud"}"
    ]
    allowed_headers = ["*"]
    expose_headers  = ["x-amz-version-id", "ETag"]
    max_age_seconds = 86400
  }
}

resource "scaleway_object_bucket_acl" "content" {
  bucket = scaleway_object_bucket.content.name
  acl    = "public-read"
}

# --- Database (MySQL) ---
resource "scaleway_rdb_instance" "main" {
  name           = "${var.project_name}-db"
  node_type      = "db-play2-pico" # General Purpose Small
  engine         = "MySQL-8"
  is_ha_cluster  = false
  disable_backup = false
  volume_type       = "sbs_15k"
  volume_size_in_gb = 10
  user_name      = "admin"
  password       = local.db_admin_password
  
  # settings = {
  #   "require_secure_transport" = "on" # Enforce SSL/TLS
  # }

  private_network {
    pn_id = scaleway_vpc_private_network.main.id
    enable_ipam = true
  }
}

resource "scaleway_rdb_database" "ghost" {
  instance_id = scaleway_rdb_instance.main.id
  name        = "ghost"
}

resource "scaleway_rdb_user" "ghost" {
  instance_id = scaleway_rdb_instance.main.id
  name        = "ghost"
  password    = local.db_app_password
  is_admin    = false
}

resource "scaleway_rdb_privilege" "ghost_access" {
  instance_id = scaleway_rdb_instance.main.id
  user_name   = scaleway_rdb_user.ghost.name
  database_name = scaleway_rdb_database.ghost.name
  permission  = "all"
}

# Allow access from anywhere (required for Serverless Containers without Private Network)
resource "scaleway_rdb_acl" "main" {
  instance_id = scaleway_rdb_instance.main.id
  acl_rules {
    ip          = "0.0.0.0/0"
    description = "Allow all (Serverless Containers have dynamic IPs)"
  }
}

# --- IAM for S3 Access ---
resource "scaleway_iam_application" "ghost_s3" {
  name            = "${var.app_name}-s3-access"
  description     = "IAM Application for Ghost container to access S3"
  organization_id = var.organization_id
}

resource "scaleway_iam_policy" "ghost_s3_policy" {
  name        = "${var.app_name}-s3-policy"
  description = "Policy for Ghost S3 access"
  application_id = scaleway_iam_application.ghost_s3.id
  rule {
    project_ids = [var.project_id]
    permission_set_names = ["ObjectStorageFullAccess"]
  }
}

resource "scaleway_iam_api_key" "ghost_s3_key" {
  application_id = scaleway_iam_application.ghost_s3.id
  description    = "API Key for Ghost S3 access"
  default_project_id  = var.project_id
}

# --- Secrets Management ---
resource "scaleway_secret" "db_password" {
  name        = "${var.app_name}-db-password"
  description = "Ghost Database Password"
}

resource "scaleway_secret_version" "db_password" {
  secret_id = scaleway_secret.db_password.id
  data      = local.db_app_password
}

resource "scaleway_secret" "s3_access_key" {
  name        = "${var.app_name}-s3-access-key"
  description = "Ghost S3 Access Key"
}

resource "scaleway_secret_version" "s3_access_key" {
  secret_id = scaleway_secret.s3_access_key.id
  data      = scaleway_iam_api_key.ghost_s3_key.access_key
}

resource "scaleway_secret" "s3_secret_key" {
  name        = "${var.app_name}-s3-secret-key"
  description = "Ghost S3 Secret Key"
}

resource "scaleway_secret_version" "s3_secret_key" {
  secret_id = scaleway_secret.s3_secret_key.id
  data      = scaleway_iam_api_key.ghost_s3_key.secret_key
}

resource "scaleway_secret" "smtp_password" {
  name        = "${var.app_name}-smtp-password"
  description = "Ghost SMTP Password"
}

resource "scaleway_secret_version" "smtp_password" {
  secret_id = scaleway_secret.smtp_password.id
  data      = var.mail_smtp_password
}

# --- VPC Private Network ---
resource "scaleway_vpc_private_network" "main" {
  name = "${var.project_name}-pn"
}

# --- Serverless Container Namespace ---
resource "scaleway_container_namespace" "main" {
  name        = "${var.project_name}-ns"
  description = "Namespace for ${var.project_name}"
  environment_variables = {
    "activate_vpc_integration" = "true"
  }
}
