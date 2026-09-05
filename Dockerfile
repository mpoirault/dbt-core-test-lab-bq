# image for the Cloud Run job. python version from .python-version, dbt from
# uv.lock, the dbt project parsed at build time. no credentials in here: the
# job runs as the dbt-core-runner service account and dbt-bigquery picks it
# up through application default credentials (method: oauth).
FROM python:3.12-slim

# build arguments for project configuration, cd_dbt passes them
ARG GCP_PROJECT

ENV PYTHONUNBUFFERED=1 \
    PATH="/usr/app/.venv/bin:/root/.local/bin/:$PATH" \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    DBT_PROFILES_DIR="." \
    DBT_PROJECT_DIR="." \
    # the prod profile target reads this at parse time and at runtime
    GCP_PROJECT=${GCP_PROJECT}

WORKDIR /usr/app/
VOLUME /usr/app

# install OS dependencies, add git if you start downloading dbt packages from git
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install ca-certificates curl -y && \
    rm -rf /var/lib/apt/lists/*

# install uv
ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh

# install python dependencies, dev tools stay out of the image
COPY pyproject.toml uv.lock .python-version ./
RUN uv sync --no-dev --frozen

COPY . .

# the dbt project lives in dbt/, the job runs its commands from here
WORKDIR /usr/app/dbt/

RUN uv run dbt deps && \
    uv run dbt parse --target prod

# no CMD: the Cloud Run job carries the command (infrastructure/cloud_run.tf)
