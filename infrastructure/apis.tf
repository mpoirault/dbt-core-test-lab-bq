# apis the stack needs. disable_on_destroy = false: a destroy should take the
# resources, not switch off apis that other things in the project (the cloud
# lab shares it) may rely on.
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
