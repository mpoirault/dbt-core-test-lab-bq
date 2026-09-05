# single env for now, its a lab. when productionalizing, dev/preprod/prod each
# get their own folder here with a backend-config and a vars file, and state is
# split per terraform workspace.
bucket = "dbt-core-test-lab-bq-tfstate"
prefix = "terraform/state"
