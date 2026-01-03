variable "organization_id" {
  description = "Scaleway Organization ID"
  type        = string
}

variable "project_id" {
  description = "Scaleway Project ID"
  type        = string
}

variable "region" {
  description = "Scaleway Region (e.g. fr-par)"
  type        = string
  default     = "fr-par"
}

variable "zone" {
  description = "Scaleway Zone (e.g. fr-par-1)"
  type        = string
  default     = "fr-par-1"
}

variable "project_name" {
  description = "Name of the project (used for naming general resources)"
  type        = string
  default     = "ghost-blog"
}

variable "app_name" {
  description = "Name of the application (used for naming resources)"
  type        = string
  default     = "ghost-blog"
}

variable "db_password" {
  description = "Password for the database user. If empty, a random one will be generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "scw_secret_key" {
  description = "Scaleway Secret Key (required for Docker login)"
  type        = string
  sensitive   = true
}

variable "custom_domain" {
  description = "Custom domain for Ghost blog (e.g., blog.example.com). Leave empty to use default container URL."
  type        = string
  default     = ""
}

variable "mail_from_address" {
  description = "Email address for sending Ghost emails (e.g., noreply@blog.example.com). If empty, will be auto-generated."
  type        = string
  default     = ""
}
