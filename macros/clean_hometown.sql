{% macro clean_hometown(column_name) %}
  lower(
    nullif(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              regexp_replace(
                cast({{ column_name }} as string),
                r'(?i)\b(n/a|unknown)\b', ''  -- Remove unclear entries like "n/a", "unknown"
              ),
              r'(?i)\b(NL|UK|USA|United States|Germany|Europe|France|Belgium|India|China|Japan|Portugal|Mexico|BR|CO|IN|AU|CA|UAE|RU|ZA|SE|CH|DK|FI|IL|IR|IE|HK|CN|EC|NZ|RO|PL|BG|GR|SK|UA|HU|LT|LV|RS|CZ|HR|AT|DE|AR|KR|TR|BRASIL|MX)\b',
              ''
            ),
            r'[0-9]', ''  -- Remove numbers / postal codes
          ),
          r'[?,-]', ''  -- Remove commas and question marks
        ),
        r'^\s*$', ''  -- Catch-all: if empty or only spaces, make it NULL
      )
    ,'')
  )
{% endmacro %}
