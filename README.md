# No More Passwords! Terraform Module Makes GCP-GitHub Authentication a Breeze

# Intro

Hello there! Welcome to our guide on automating OpenID Connect (OIDC) using Terraform with Google Cloud Platform (GCP) to grant access to GitHub Actions.

# Overview

In this post, we'll dive into the seamless integration of OIDC, enabling GitHub Actions workflows to access GCP resources without the need to store long-lived GCP credentials as GitHub secrets.

# Prerequisites

Before we begin, ensure you have the following prerequisites:

- Installed Terraform CLI
- Installed gcloud CLI
- Access to a Google Cloud Platform (GCP) Project
- Access to a Github repository

# Next Steps

Let's jump into the configuration process to make this integration work seamlessly.

## Setting Up Terraform:

**Create a Project Folder**: Start by creating a folder for your Terraform configuration and navigate into it:

```bash
mkdir terraform-oidc
cd terraform-oidc
```

**Set Terraform Variables**: Create a file called `variables.tf` and past the following configuration into it:

```js
variable "project" {
  default = "dev-to-oidc" // replace with your project id
}

variable "credentials_file" {
  default = "~/.config/gcloud/application_default_credentials.json" // replace with your credentials path
}

variable "region" {
  default = "us-central1" // replace with your region
}

variable "zone" {
  default = "us-central1-f" // replace with your zone
}

variable "gh_repo" {
  default = "manganellidev/dev-to-oidc-gcp-tf" // replace with your organization/repository
}
```

**Set Terraform Configuration**: Create a file called `main.tf` and past the following Terraform configuration into it:

```js
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
```

**Initialize Terraform**:

```bash
terraform init
```

**Login to GCP**:

```bash
gcloud auth login
```

**Set target GCP project**:

```bash
# replace dev-to-oidc with your project id
gcloud config set project dev-to-oidc
```

**Apply Terraform**:

```bash
terraform apply

# Review the changes than type yes + enter
# Copy the service account email from the output in the terminal and save it to be used later (e.g oidc-service-account@dev-to-oidc.iam.gserviceaccount.com)
```

**Get Workload Identity Provider**:

```bash
gcloud iam workload-identity-pools providers list --location="global" --workload-identity-pool="oidc-pool"

# Copy the name value and save it to be used later (e.g projects/123123123123/locations/global/workloadIdentityPools/oidc-pool/providers/oidc-gh-provider)
```

## Setting Up GitHub Actions:

**Create Github Workflow**:

```bash
mkdir .github
mkdir .github/workflows
touch .github/workflows/workflow-test.yml
```

```yml
on:
  workflow_call:

  push:
    branches:
      - "main"

jobs:
  auth-oidc:
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    steps:
      - name: Google Auth
        uses: google-github-actions/auth@v2
        with:
          token_format: access_token
          project_id: dev-to-oidc
          service_account: oidc-service-account@dev-to-oidc.iam.gserviceaccount.com # replace with your service account name
          workload_identity_provider: projects/123123123123/locations/global/workloadIdentityPools/oidc-pool/providers/oidc-gh-provider # replace with your WIF provider name

      - name: Docker Auth
        uses: "docker/login-action@v1"
        with:
          username: "oauth2accesstoken"
          password: "${{ steps.auth.outputs.access_token }}"
          registry: "us-central1-docker.pkg.dev" # replace with your region

      - name: "Set up Cloud SDK"
        uses: "google-github-actions/setup-gcloud@v2"

      - name: Use gcloud CLI
        run: |
          gcloud auth list --filter=status:ACTIVE --format="value(account)"
```

## Testing the Integration:

## Conclusion:

With this Terraform module, you can streamline the authentication process between GitHub Actions and Google Cloud Platform, eliminating the need for managing and storing sensitive credentials. Stay tuned for more tips and tricks on optimizing your cloud workflows!

<hr/>
<br/>

That's it! Happy coding! 🎉🎉🎉
