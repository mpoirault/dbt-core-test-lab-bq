terraform {
  required_version = "~> 1.15.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.33.0"
    }
  }

  # empty on purpose. the actual bucket/prefix come from
  # env/lab/backend-config.tfvars at init time:
  #   terraform init -backend-config=env/lab/backend-config.tfvars
  # with more envs each one gets its own backend-config plus a terraform
  # workspace. the state bucket itself is made by hand (chicken and egg,
  # you need state to manage the bucket that holds the state).
  backend "gcs" {
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
