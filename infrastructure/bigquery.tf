module "bq_datasets" {
  for_each = local.core_datasets
  source   = "./modules/bigquery_dataset"

  dataset_id  = each.key
  description = each.value
  location    = var.gcp_region
  project     = var.gcp_project

  labels = {
    managed_by = "terraform"
    runtime    = "dbt_core"
    repo       = var.gh_repo_name
  }

  depends_on = [google_project_service.this]
}
