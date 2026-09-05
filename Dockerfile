# image for the Cloud Run job. dbt-bigquery from uv.lock, the dbt project
# under /app/dbt, packages and manifest built in. no credentials in here:
# the job runs as the dbt-core-runner service account and dbt-bigquery
# picks that up through application default credentials (method: oauth).
ARG PYTHON_VERSION=3.12

FROM python:${PYTHON_VERSION}-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.11.28 /uv /usr/local/bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY pyproject.toml uv.lock ./
# runtime deps only, the dev group (linters, bouncer) stays out of the image
RUN uv sync --frozen --no-dev --no-install-project

FROM python:${PYTHON_VERSION}-slim AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH" \
    DBT_PROFILES_DIR=/app/dbt

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

# non-root, Cloud Run does not need root and checkov asks for it
RUN useradd --create-home --uid 1000 dbt
WORKDIR /app
COPY --from=builder --chown=dbt:dbt /app/.venv /app/.venv
COPY --chown=dbt:dbt dbt/ /app/dbt/
USER dbt
WORKDIR /app/dbt

# packages and a parsed manifest at build time, so a broken project fails the
# image build, not the prod run. parse needs no warehouse.
RUN dbt deps && dbt parse --target prod

# no CMD: the Cloud Run job carries the command (infrastructure/cloud_run.tf)
