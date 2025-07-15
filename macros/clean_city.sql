-- macros/clean_city.sql
{% macro clean_city(column_name) %}
  lower(
    nullif(
      trim(
        case
          when regexp_contains(cast({{ column_name }} as string), r'(?i)amsterdam') then 'amsterdam'
          else
            regexp_replace(
              regexp_replace(
                regexp_replace(
                  regexp_replace(
                    regexp_replace(
                      cast({{ column_name }} as string),
                      r'[\r\n]',  -- Remove carriage returns and newlines
                      ''
                    ),
                    r'(?i)\b(n/a|unknown|nederland|near\s+)',  -- Remove noise
                    ''
                  ),
                  r'(?i)(^|\s|,)(D-\d{4,5}|\d{4,5}\s*[A-Z]{0,2}|\d{5}(?:-\d{4})?)(\s|,|$)',  -- Postal codes
                  ' '
                ),
                r'(^,+|,+$)',  -- Remove leading or trailing commas
                ''
              ),
              r'\s{2,}', ' '  -- Collapse multiple spaces
            )
        end
      ),
      ''
    )
  )
{% endmacro %}
