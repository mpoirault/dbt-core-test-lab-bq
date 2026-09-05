variable "gcp_project" {
  description = "GCP project id where BigQuery, Artifact Registry and the Cloud Run job live."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for regional resources (BigQuery datasets, Artifact Registry, Cloud Run)."
  type        = string
}

variable "state_bucket" {
  description = "Name of the GCS bucket holding the terraform state. Created once by hand (see README setup); must match the bucket in env/<env>/backend-config.tfvars, since backend blocks cannot read variables."
  type        = string
}

variable "gh_repo_name" {
  description = "Name of the GitHub repository (feeds the repo label on datasets)."
  type        = string
}

variable "ar_repository" {
  description = "Artifact Registry docker repository that holds the dbt image."
  type        = string
  default     = "dbt-core-test-lab-bq"
}

variable "cloud_run_job_name" {
  description = "Name of the Cloud Run job that builds prod. cd_dbt updates and executes it by this name."
  type        = string
  default     = "dbt-core-prod-build"
}
