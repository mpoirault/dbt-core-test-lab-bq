resource "google_storage_bucket" "terraform_state" {
  name                     = "terraform-state-${var.project_id}"
  location                 = "EU"
  force_destroy            = true
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}