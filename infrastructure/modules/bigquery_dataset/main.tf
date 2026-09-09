resource "google_bigquery_dataset" "this" {
  # checkov:skip=CKV_GCP_81: google managed encryption is enough for a lab.
  # Revisit before real data lands here.

  dataset_id  = var.dataset_id
  description = var.description
  location    = var.location
  project     = var.project

  delete_contents_on_destroy = false

  labels = var.labels
}
