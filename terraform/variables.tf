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

variable "mail_from_name" {
  description = "Display name for outgoing emails"
  type        = string
  default     = "My Ghost Blog"
}

variable "mail_from_email" {
  description = "Email address for outgoing emails"
  type        = string
  default     = "noreply@blog.example.com"
}

variable "mail_smtp_host" {
  description = "SMTP server hostname"
  type        = string
  default     = "smtp.mailgun.org"
}

variable "mail_smtp_port" {
  description = "SMTP server port"
  type        = string
  default     = "587"
}

variable "mail_smtp_secure" {
  description = "Use TLS/SSL for SMTP (false for STARTTLS on 587)"
  type        = string
  default     = "false"
}

variable "mail_smtp_user" {
  description = "SMTP authentication username"
  type        = string
  default     = "postmaster@mg.example.com"
}

variable "mail_smtp_password" {
  description = "SMTP authentication password"
  type        = string
  sensitive   = true
}
