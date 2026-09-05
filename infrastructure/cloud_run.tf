# the dbt image lives here. cd_dbt pushes <sha> and latest on every merge to
# main. the cleanup policy keeps the registry from growing forever.
resource "google_artifact_registry_repository" "dbt" {
  # checkov:skip=CKV_GCP_84: CMEK is overkill for a personal lab, google managed
  # encryption is fine. same call as on the datasets.
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

# the prod build. same two steps as the cloud labs merge job: seed, then
# build everything but seeds. runs as the runner SA, dbt-bigquery picks it
# up as application default credentials. cd_dbt updates the image tag on
# every merge and then executes the job, so the image is ignored here:
# otherwise every deploy would show up as drift and fail ci_terraform.
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
        # bootstrap image only, googles public hello-job. the first cd_dbt
        # run swaps it for the real one and terraform ignores the image from
        # then on (see lifecycle). cloud run refuses a job whose image does
        # not exist yet, this way the first apply is one pass.
        image   = "us-docker.pkg.dev/cloudrun/container/job:latest"
        command = ["bash", "-c"]
        args    = ["dbt seed --target prod && dbt build --target prod --exclude resource_type:seed"]

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
