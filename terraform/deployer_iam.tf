resource "scaleway_iam_application" "deployer" {
  name            = "${var.project_name}-deployer"
  description     = "IAM Application for Terraform Deployment"
  organization_id = var.organization_id
}

resource "scaleway_iam_policy" "deployer_policy" {
  name           = "terraform-deploy-policy"
  description    = "Policy for Terraform Deployer"
  application_id = scaleway_iam_application.deployer.id
  rule {
    organization_id = var.organization_id
    permission_set_names = [
      "IAMManager",
    ]
  }
  rule {
    project_ids = [var.project_id]
    permission_set_names = [
      "ContainerRegistryFullAccess",
      "ObjectStorageFullAccess",
      "SecretManagerFullAccess",
      "PrivateNetworksFullAccess",
      "ContainersFullAccess",
      "RelationalDatabasesFullAccess",
    ]
  }
}

resource "scaleway_iam_api_key" "deployer_key" {
  application_id = scaleway_iam_application.deployer.id
  description    = "API Key for Terraform Deployer"
  default_project_id  = var.project_id
}

output "deployer_access_key" {
  value = scaleway_iam_api_key.deployer_key.access_key
}

output "deployer_secret_key" {
  value     = scaleway_iam_api_key.deployer_key.secret_key
  sensitive = true
}
