terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.27.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_project_service" "iam_credentials_api" {
  project = var.project
  service = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "oidc_service_account" {
  project      = var.project
  account_id   = "oidc-service-account"
  display_name = "OIDC Service Account"
  description  = "This service account is used for my application to interact with Google Cloud services."
}

module "gh_oidc" {
  source      = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  project_id  = var.project
  pool_id     = "oidc-pool"
  provider_id = "oidc-gh-provider"
  attribute_mapping = {
    "attribute.repository": "assertion.repository",
    "google.subject": "assertion.sub"
  }
  sa_mapping = {
    "oidc-service-account" = {
      sa_name   = "projects/${var.project}/serviceAccounts/${google_service_account.oidc_service_account.email}"
      attribute = "attribute.repository/${var.gh_repo}"
    }
  }
}

output "service_account_email" {
  value = google_service_account.oidc_service_account.email
}
