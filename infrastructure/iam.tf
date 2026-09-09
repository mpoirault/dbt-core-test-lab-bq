# Four identities, one job each. No google_service_account_key resources:
# the runner is attached to the Cloud Run job and needs no key.
# The other three get a key minted with gcloud and pasted into a GitHub secret,
# so no private key ever sits in terraform state.

# --- prod runner ---
resource "google_service_account" "dbt_core_runner" {
  account_id   = "dbt-core-runner"
  display_name = "dbt Core runner"
  description  = "Identity of the dbt-core-prod-build Cloud Run job. Writes the core_* datasets, nothing else."
  project      = var.gcp_project
}

resource "google_project_iam_member" "dbt_core_runner_jobs" {
  project = var.gcp_project
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt_core_runner.email}"
}

# Dataset level on purpose, the runner touches only the datasets terraform made for it.
resource "google_bigquery_dataset_iam_member" "dbt_core_runner" {
  for_each   = module.bq_datasets
  project    = var.gcp_project
  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt_core_runner.email}"
}

# --- PR CI ---
# bigquery.user lets it create the dbt_core_pr_<number> dataset and own it,
# which is how the workflow drops the dataset again.
# Read on core_*: staging selects from the shared core_raw and docs generate reads prod.
resource "google_service_account" "dbt_core_ci" {
  account_id   = "dbt-core-ci"
  display_name = "dbt Core CI"
  description  = "PR builds in GitHub Actions (ci_dbt) and docs generation. Creates its own dbt_core_pr_* dataset, reads core_*, never writes prod."
  project      = var.gcp_project
}

resource "google_project_iam_member" "dbt_core_ci_user" {
  project = var.gcp_project
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.dbt_core_ci.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_core_ci" {
  for_each   = module.bq_datasets
  project    = var.gcp_project
  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.dbt_core_ci.email}"
}

# --- deploy, cd_dbt ---
# run.developer covers update and execute on the job.
# serviceAccountUser on the runner is what lets it deploy a job that runs as the runner.
resource "google_service_account" "dbt_core_deploy" {
  account_id   = "dbt-core-deploy"
  display_name = "dbt Core deploy"
  description  = "cd_dbt in GitHub Actions: push the dbt image, update and execute the Cloud Run job."
  project      = var.gcp_project
}

resource "google_artifact_registry_repository_iam_member" "dbt_core_deploy" {
  project    = var.gcp_project
  location   = var.gcp_region
  repository = google_artifact_registry_repository.dbt.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.dbt_core_deploy.email}"
}

resource "google_project_iam_member" "dbt_core_deploy_run" {
  project = var.gcp_project
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.dbt_core_deploy.email}"
}

resource "google_service_account_iam_member" "dbt_core_deploy_act_as_runner" {
  service_account_id = google_service_account.dbt_core_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.dbt_core_deploy.email}"
}

# --- plan only, ci_terraform ---
# The -core suffix: another lab in this project already owns terraform-plan-ci.
# Granular read roles instead of roles/viewer, checkov CKV_GCP_117.
resource "google_service_account" "terraform_plan_ci" {
  account_id   = "terraform-plan-ci-core"
  display_name = "Terraform plan (PR CI, core lab)"
  description  = "Read-only identity for terraform plan in GitHub Actions PR CI. No apply permissions."
  project      = var.gcp_project
}

locals {
  terraform_plan_ci_roles = [
    "roles/artifactregistry.reader",
    "roles/bigquery.metadataViewer",
    "roles/iam.securityReviewer",
    "roles/iam.serviceAccountViewer",
    "roles/run.viewer",
    "roles/serviceusage.serviceUsageViewer",
  ]
}

resource "google_project_iam_member" "terraform_plan_ci" {
  for_each = toset(local.terraform_plan_ci_roles)
  project  = var.gcp_project
  role     = each.value
  member   = "serviceAccount:${google_service_account.terraform_plan_ci.email}"
}

# The gcs backend writes a lock object even for plan, so plan needs write on the bucket.
# var.state_bucket must match env/<env>/backend-config.tfvars by hand,
# the backend block cannot read variables.
resource "google_storage_bucket_iam_member" "terraform_plan_ci_state" {
  bucket = var.state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform_plan_ci.email}"
}
