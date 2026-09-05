{#
  schema routing per target. custom_schema_name is the +schema value from
  dbt_project.yml (raw / staging / intermediate / marts), the prod dataset
  for a stage is always core_<stage>.

  - prod: core_<stage>                        e.g. core_marts
  - ci:   everything goes into target.schema as is. on a PR that is the
    dbt_core_pr_<number> dataset ci_dbt creates for the run, and keeping all
    models in that one dataset is what lets the workflow drop it in one
    command at the end (suffixed datasets would just linger).
  - dev (anything else): <target.schema>_core_<stage>, e.g. dbt_mpoirault_core_marts
  - raw is shared: seeds and snapshots build into core_raw in every target
    and all targets read sources from there. exception is ci, its snapshots
    stay in the PR dataset too, ci must never write to shared raw.
  - no +schema set: falls back to target.schema.

  target.schema is the dataset of your profile target, for dev thats
  DBT_DATASET or dbt_<user> (see profiles.yml). the Cloud Run job has to use
  target name "prod" and ci_dbt "ci", this macro keys on those.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if custom_schema_name is none or target.name == "ci" -%} {{ target.schema }}
    {%- else -%}
        {%- set prod_schema = "core_" ~ custom_schema_name | trim -%}
        {%- if target.name == "prod" or custom_schema_name | trim == "raw" -%}
            {{ prod_schema }}
        {%- else -%} {{ target.schema }}_{{ prod_schema }}
        {%- endif -%}
    {%- endif -%}

{%- endmacro %}
