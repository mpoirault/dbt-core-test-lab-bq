# cd_dbt pushes <sha> and latest on every merge to main.
resource "google_artifact_registry_repository" "dbt" {
  # checkov:skip=CKV_GCP_84: google managed encryption is enough for a lab.
  project       = var.gcp_project
  location      = var.gcp_region
  repository_id = var.ar_repository
  description   = "dbt image for the ${var.cloud_run_job_name} Cloud Run job."
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      older_than = "2592000s" # 30 days
    }
  }

  depends_on = [google_project_service.this]
}

# The prod build. dbt-bigquery authenticates as the runner SA
# through application default credentials.
# cd_dbt sets the image tag on every merge, so terraform ignores it.
# Without that, each deploy is drift and ci_terraform fails.
resource "google_cloud_run_v2_job" "dbt" {
  name                = var.cloud_run_job_name
  location            = var.gcp_region
  project             = var.gcp_project
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.dbt_core_runner.email
      timeout         = "1800s"
      max_retries     = 0

      containers {
        # Bootstrap image, Cloud Run refuses a job whose image does not exist yet.
        # The first cd_dbt run replaces it.
        image   = "us-docker.pkg.dev/cloudrun/container/job:latest"
        command = ["bash", "-c"]
        args    = ["dbt build --target prod"]

        env {
          name  = "GCP_PROJECT"
          value = var.gcp_project
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [
    google_project_service.this,
    google_artifact_registry_repository.dbt,
  ]
}
