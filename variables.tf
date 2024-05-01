variable "project" {
  default = "dev-to-oidc"
}

variable "credentials_file" {
  default = "~/.config/gcloud/application_default_credentials.json"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-f"
}

variable "gh_repo" {
  default = "manganellidev/dev-to-oidc-gcp-tf"
}

