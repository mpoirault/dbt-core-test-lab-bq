{% macro clean_string(column_name) %}
    nullif(trim(lower({{ column_name }})), '')
{% endmacro %} 