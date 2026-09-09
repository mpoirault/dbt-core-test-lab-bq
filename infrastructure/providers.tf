terraform {
  required_version = "~> 1.15.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.33.0"
    }
  }

  # Empty on purpose. Bucket and prefix come from env/<env>/backend-config.tfvars at init.
  # The bucket itself is made by hand, terraform cannot manage its own backend.
  backend "gcs" {
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
