# disable_on_destroy = false: other stacks in this project share these apis.
locals {
  apis = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "this" {
  for_each = toset(local.apis)
  project  = var.gcp_project
  service  = each.value

  disable_on_destroy = false
}
