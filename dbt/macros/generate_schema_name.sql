{#
  Schema routing per target. custom_schema_name is the +schema value from dbt_project.yml.

  - prod: core_<stage>.
  - ci: everything goes into target.schema, the dbt_core_pr_<number> dataset of the run.
    One dataset is what lets ci_dbt drop it in one command at the end.
  - dev, anything else: <target.schema>_core_<stage>.
  - raw is shared. Seeds and snapshots build into core_raw in every target
    and all targets read sources from there.
    Exception: ci keeps its snapshots in the PR dataset, ci must never write to shared raw.

  The Cloud Run job must use target name "prod" and ci_dbt "ci", this macro keys on those.
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
