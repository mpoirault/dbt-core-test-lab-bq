# dbt-core-test-lab-bq

This is my personal lab for playing around with dbt Core on BigQuery.
It is the sibling of [dbt-cloud-test-lab](https://github.com/mpoirault/dbt-cloud-test-lab):
same dbt project, same toolchain, same AI workflow, one lab per runtime.
Everything that is `cloud_` there is `core_` here.

## What's here

- `infrastructure/`: everything terraform manages. The BigQuery datasets, four service accounts with dataset scoped roles, the Artifact Registry repo and the Cloud Run job that builds prod
- `dbt/`: the dbt project, built on the jaffle-shop seeds. Seeds sit behind `source()` with freshness checks, an SCD2 snapshot feeds staging, then intermediate and marts. `dbt-bouncer.yml` enforces the modeling standards. `profiles.yml` is committed, it holds three oauth targets and no secrets
- `Dockerfile`: the image the Cloud Run job runs. dbt-bigquery from `uv.lock`, the project parsed at build time, no credentials inside
- CI: `ci_dbt` lints, runs bouncer and builds the whole project into a throwaway `dbt_core_pr_<number>` dataset that the same run drops again. `ci_terraform` plans and fails on drift
- CD: merging to main runs `cd_dbt`. It builds the image, pushes it, rolls the Cloud Run job to it and executes the job (seed, then build). `cd_dbt_docs` follows a green `cd_dbt` and publishes the dbt docs to GitHub Pages

### AI-assisted workflow

This repo doubles as a demo and testing ground for an AI-assisted development workflow.
Coding agents (Claude Code, Gemini CLI) get their instructions from [`AGENTS.md`](AGENTS.md),
which `CLAUDE.md` and `GEMINI.md` import.

The workflow itself is the
[test-lab-learning plugin](https://github.com/mpoirault/development-learning-workflow),
enabled for this repo in `.claude/settings.json`.
Start Claude Code from the repo root, not from `dbt/` or `infrastructure/`.
Project settings, and with them the plugin and its guardrail hook,
load from the directory where the session starts.
It brings three skills and a guardrail hook that denies any file mutation on main:

- `flow` branches from fresh `origin/main` before the first edit and routes the end of a task.
- `explore` (typed `/test-lab-learning:explore`) runs a learning spike on a concept, an article, or a link:
  a grounded briefing, a concept page under [`explorations/`](explorations/),
  and a forced verdict (implement now, park, or drop). Every verdict lands in [`IDEAS.md`](IDEAS.md).
- `debrief` fires at the end of a task, before the commit proposal: one guided question,
  a concept walk of the diff, a teach-back with a TODO(human) blank,
  and a residual note saved to the knowledge base only on approval.

Commit and PR creation are personal skills on my machine (`commit`, `pr`).
The plugin detects them by description and falls back to plain git when they are absent.

### Infrastructure layout

`infrastructure/` follows the usual terraform repo shape: a flat root with topic files, a `modules/` map, and an `env/` folder.

```text
infrastructure/
├── providers.tf          # terraform block, empty gcs backend, google provider
├── locals.tf
├── variables.tf
├── apis.tf               # the apis the stack needs
├── bigquery.tf           # calls modules/bigquery_dataset per dataset
├── iam.tf                # runner, ci, deploy and plan SAs with their roles
├── cloud_run.tf          # artifact registry repo + the prod build job
├── modules/
│   └── bigquery_dataset/
└── env/
    └── lab/              # backend-config.tfvars + vars.tfvars(.example)
```

There is only one env (`lab`), a real env split is too much for a demo. The folder exists anyway because that's where productionalisation starts: dev/preprod/prod each get their own backend-config and vars file there, state split per terraform workspace. The backend block is empty on purpose, the bucket and prefix come from `env/lab/backend-config.tfvars` at init time.

## Decisions

- dbt code lives in the `dbt/` subdir, same as the cloud lab
- Three profile targets, all `oauth`: `dev` is your gcloud login, `prod` is the runner SA attached to the Cloud Run job, `ci` is the CI SA key activated in the workflow. No key file is ever referenced, so `profiles.yml` is committed
- Four SAs, each scoped to one job. `dbt-core-runner` edits the five `core_*` datasets and nothing else. `dbt-core-ci` can create and drop its own `dbt_core_pr_*` dataset and read `core_*`, it cannot write prod. `dbt-core-deploy` pushes one image and updates or runs one job. `terraform-plan-ci-core` reads. The `-core` suffix is there because the cloud lab already owns `terraform-plan-ci` in the same project
- SA keys in GitHub secrets, not workload identity federation. Same as the cloud lab, WIF is the obvious next step for both
- Datasets: raw is shared (`core_raw` in every target, seeds load once). Dev models build to `<your dataset>_core_<stage>`, prod to `core_<stage>`. The routing sits in one macro, `dbt/macros/generate_schema_name.sql`, and keys on the target name
- CI builds the whole project, not `state:modified+`. Slim CI needs a prod manifest in a bucket, IAM on it and a download step. That's more infra than a lab needs and the project builds in under a minute. The exact command it would use is a comment in `ci_dbt.yml`
- CD is the merge: build image, push, roll the job, execute it. No cron, no alerting. The manual prod run is the same workflow dispatched by hand, gated by the `prod` environment
- The Cloud Run job is terraform managed but its image tag is not: `ignore_changes` on the image, so a deploy never shows up as drift in `ci_terraform`
- `terraform plan` runs in `ci_terraform` under the read-only SA. If there is drift, the pipeline fails
- dbt-bouncer runs on every local commit and again in `ci_dbt` on PRs that touch `dbt/` (manifest checks only), which comments failures on the PR
- Toolchain split: binaries (terraform, uv) are pinned in `mise.toml`, Python itself and every python tool including dbt in `pyproject.toml` + `uv.lock`. Pre-commit hooks call tools through `uv run` so hooks, editor, CI and the Docker image resolve the same versions
- Decisions live here in the README; [`IDEAS.md`](IDEAS.md) only logs /explore verdicts. A decision is settled, a parked idea is not.

## Setup

One prerequisite: [mise](https://mise.jdx.dev/getting-started.html) (`curl https://mise.run | sh`, then add `eval "$(~/.local/bin/mise activate bash)"` to your shell rc). Everything else is pinned in the repo:

```bash
mise trust && mise run setup

# infra
cd infrastructure
cp env/lab/vars.tfvars.example env/lab/vars.tfvars   # fill in, gitignored
gcloud auth application-default login

# one-time: create the state bucket. terraform cannot manage its own backend
gcloud storage buckets create gs://<your-tfstate-bucket> \
  --location=<region> --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update gs://<your-tfstate-bucket> --versioning

terraform init -backend-config=env/lab/backend-config.tfvars
terraform plan -var-file=env/lab/vars.tfvars
terraform apply -var-file=env/lab/vars.tfvars
```

The Cloud Run job starts on Google's public hello-job image, the first `cd_dbt` run swaps in the real one. Terraform ignores the image tag from then on.

### CI configuration (once, after the first apply)

The workflows need the non-secret tfvars mirrored as GitHub repo variables plus three secrets (values are never committed):

```bash
# variables, same values as env/lab/vars.tfvars
gh variable set GCP_PROJECT     # gcp_project
gh variable set GCP_REGION      # gcp_region
gh variable set STATE_BUCKET    # state_bucket (also the bucket in backend-config.tfvars)
gh variable set GH_REPO_NAME    # gh_repo_name
gh variable set AR_REPOSITORY   # ar_repository, default dbt-core-test-lab-bq
gh variable set CLOUD_RUN_JOB   # cloud_run_job_name, default dbt-core-prod-build

# secrets, prompted on stdin so nothing lands in shell history. one key per SA:
# gcloud iam service-accounts keys create key.json \
#   --iam-account=<sa>@<gcp_project>.iam.gserviceaccount.com
# (paste key.json contents into the secret, then delete the file)
gh secret set GCP_CI_SA_KEY                       # terraform-plan-ci-core
gh secret set GCP_DBT_CI_SA_KEY                   # dbt-core-ci
gh secret set GCP_DEPLOY_SA_KEY --env prod        # dbt-core-deploy, environment only
```

The `prod` environment (repo settings, Environments) has a deployment branch policy of `main` and me as required reviewer. That is what keeps the manual prod run mine on a public repo: `workflow_dispatch` already needs write access, and on top of that the deploy key is only handed to a run from main after an approval. Pages source is GitHub Actions, and main requires a PR.

### dbt Core locally

`mise run setup` gives you a venv with dbt-bigquery in it. Activate it and run dbt from `dbt/`:

```bash
source .venv/bin/activate
gcloud auth application-default login     # once, dbt-bigquery reads ADC
cd dbt
dbt deps
dbt build                                 # target dev, builds into dbt_<you>_core_<stage>
```

The dev target takes its dataset from `DBT_DATASET`, default `dbt_<your unix user>`. Shared raw stays in `core_raw` for everyone. Never run `--target prod` from a laptop, that is the Cloud Run job's target and your ADC has no write on `core_*` anyway.

VS Code: the [dbt Power User](https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user) extension in core mode finds dbt through the venv interpreter that the committed `.vscode/settings.json` points at. Nothing else to wire up.

## License

MIT, see [LICENSE](LICENSE).
