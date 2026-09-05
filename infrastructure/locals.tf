locals {
  core_datasets = {
    core_raw          = "Landing zone for ingested data (dbt Core)."
    core_staging      = "dbt Core staging layer (1:1 with sources, light typing/renaming)."
    core_intermediate = "dbt Core intermediate layer (joins, business logic building blocks)."
    core_marts        = "dbt Core marts layer (consumption-ready models)."
    core_seeds        = "dbt Core seeds layer (raw data for seeding models)."
  }

  dbt_image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${var.ar_repository}/dbt"
}
