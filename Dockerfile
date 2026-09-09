# Python from .python-version, dbt from uv.lock, the dbt project parsed at build time.
# No credentials in here. The job runs as the runner SA
# and dbt-bigquery picks it up through application default credentials.
FROM python:3.12-slim

ARG GCP_PROJECT

ENV PYTHONUNBUFFERED=1 \
    PATH="/usr/app/.venv/bin:/root/.local/bin/:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    DBT_PROFILES_DIR="." \
    DBT_PROJECT_DIR="." \
    # The prod target reads this at parse time and at runtime.
    GCP_PROJECT=${GCP_PROJECT}

WORKDIR /usr/app/
VOLUME /usr/app

# Add git here if dbt packages ever come from git.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install ca-certificates curl -y && \
    rm -rf /var/lib/apt/lists/*

ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh

COPY pyproject.toml uv.lock .python-version ./
RUN uv sync --no-dev --frozen

COPY . .

WORKDIR /usr/app/dbt/

RUN uv run dbt deps && \
    uv run dbt parse --target prod

# No CMD, the Cloud Run job carries the command (infrastructure/cloud_run.tf).
