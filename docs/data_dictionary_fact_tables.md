# Data Dictionary: Fact Tables

This document provides detailed information about the fact tables in the Xebia Case dbt project, including column definitions, data types, and descriptions.

## Table of Contents

1. [fct_event_rsvps](#fct_event_rsvps)
2. [fct_event_rsvp_summary](#fct_event_rsvp_summary)

---

## fct_event_rsvps

A fact table containing individual RSVP records for events. This table represents the many-to-many relationship between users and events via RSVPs.

### Configuration
- **Materialization**: Incremental
- **Unique Key**: rsvp_key
- **Partition By**: rsvp_date (date)
- **Cluster By**: rsvp_key

### Columns

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| **rsvp_key** | string | Surrogate key for the RSVP record (combination of event_id, user_id, and rsvp_time_ts) |
| **event_key** | string | Foreign key to the event dimension |
| **venue_key** | string | Foreign key to the venue dimension |
| **group_key** | string | Foreign key to the group dimension |
| **user_key** | string | Foreign key to the user dimension |
| **rsvp_response** | string | The user's response to the event invitation (yes, no, waitlist) |
| **guest_count** | integer | Number of additional guests the user is bringing |
| **rsvp_limit** | integer | Maximum number of RSVPs allowed for the event |
| **rsvp_time_ts** | timestamp | When the user responded to the event |
| **rsvp_date** | date | Date of the RSVP response |
| **event_series_number** | integer | If part of a series, the number of the event in the series |
| **hours_before_event** | integer | Hours between the RSVP time and the event time |
| **days_before_event** | integer | Days between the RSVP time and the event time |
| **is_attending** | boolean | Flag indicating if the user is attending (rsvp_response = 'yes') |
| **has_guests** | boolean | Flag indicating if the user is bringing guests (guest_count > 0) |
| **dbt_updated_at** | timestamp | When this record was last updated by dbt |

### Usage Notes
- This table captures the individual RSVP actions for each user-event combination
- For incremental loads, only new RSVPs since the last run are processed
- Each record represents one user's RSVP to one event

---

## fct_event_rsvp_summary

A fact table containing summary metrics for event RSVPs, aggregated at the event level.

### Configuration
- **Materialization**: Incremental
- **Unique Key**: event_key
- **Partition By**: event_time_ts (day)
- **Cluster By**: event_key

### Columns

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| **event_key** | string | Primary key, references the event dimension |
| **group_key** | string | Foreign key to the group dimension |
| **venue_key** | string | Foreign key to the venue dimension |
| **event_time_ts** | timestamp | When the event occurs/occurred |
| **total_possible_responses** | integer | Total number of group members who could potentially respond to the event |
| **total_rsvp_responses** | integer | Total number of members who provided any RSVP response (yes, no, or waitlist) |
| **yes_responses** | integer | Number of members who responded 'yes' to the event |
| **explicit_no_responses** | integer | Number of members who explicitly responded 'no' to the event |
| **waitlist_responses** | integer | Number of members who are on the waitlist for the event |
| **total_guests** | integer | Total number of additional guests indicated in RSVPs |
| **avg_days_before_event** | float | Average number of days before the event that members RSVP |
| **rsvp_rate** | float | Rate of possible attendees who provided any RSVP response (total_rsvp_responses / total_possible_responses) |
| **yes_rate_of_responses** | float | Rate of actual responses that were 'yes' (yes_responses / total_rsvp_responses) |
| **no_rate_of_responses** | float | Rate of actual responses that were explicit 'no' (explicit_no_responses / total_rsvp_responses) |
| **total_no_responses** | integer | Number of members who did not respond positively (includes both explicit 'no' and non-responses) |
| **yes_rate** | float | Rate of possible attendees who responded 'yes' (yes_responses / total_possible_responses) |
| **waitlist_rate** | float | Rate of possible attendees on waitlist (waitlist_responses / total_possible_responses) |
| **total_no_rate** | float | Rate of possible attendees who did not respond positively (total_no_responses / total_possible_responses) |
| **explicit_no_rate** | float | Rate of possible attendees who explicitly said no (explicit_no_responses / total_possible_responses) |
| **no_response_rate** | float | Rate of possible attendees who did not provide any response ((total_possible_responses - total_rsvp_responses) / total_possible_responses) |
| **dbt_updated_at** | timestamp | When this record was last updated by dbt |

### Usage Notes
- This table provides pre-calculated metrics for event analysis and reporting
- Each record represents a single event with its associated RSVP metrics
- The metrics calculate various response rates relative to both total membership and total responses
- This table powers the analytics_event_summary model

### Metric Definitions

| Metric | Definition | Formula |
|--------|------------|---------|
| total_possible_responses | The total number of group members who could potentially respond to the event | Count of group members at event creation time |
| total_rsvp_responses | The total number of members who provided any RSVP response (yes, no, or waitlist) | Count of all RSVPs for the event |
| yes_responses | The number of members who responded 'yes' to the event | Count of 'yes' RSVPs |
| explicit_no_responses | The number of members who explicitly responded 'no' to the event | Count of explicit 'no' RSVPs |
| waitlist_responses | The number of members who are on the waitlist for the event | Count of waitlist RSVPs |
| total_no_responses | The total number of non-positive responses | total_possible_responses - yes_responses - waitlist_responses |
| total_guests | The total number of additional guests indicated in RSVPs | Sum of guest counts from all RSVPs |
| avg_days_before_event | The average number of days before the event that members RSVP | Average of days_before_event across all RSVPs |
| rsvp_rate | Rate of possible attendees who provided any RSVP response | total_rsvp_responses / total_possible_responses |
| yes_rate_of_responses | Rate of actual responses that were 'yes' | yes_responses / total_rsvp_responses |
| no_rate_of_responses | Rate of actual responses that were explicit 'no' | explicit_no_responses / total_rsvp_responses |
| yes_rate | Rate of possible attendees who responded 'yes' | yes_responses / total_possible_responses |
| waitlist_rate | Rate of possible attendees on waitlist | waitlist_responses / total_possible_responses |
| total_no_rate | Rate of possible attendees who did not respond positively | total_no_responses / total_possible_responses |
| explicit_no_rate | Rate of possible attendees who explicitly said no | explicit_no_responses / total_possible_responses |
| no_response_rate | Rate of possible attendees who did not provide any response | (total_possible_responses - total_rsvp_responses) / total_possible_responses |

---

## Relationships Between Fact Tables

The `fct_event_rsvps` and `fct_event_rsvp_summary` tables are related in the following ways:

- `fct_event_rsvps` contains individual RSVP records at the user-event level
- `fct_event_rsvp_summary` aggregates these RSVPs to the event level with pre-calculated metrics
- Both tables share common keys (event_key, group_key, venue_key) for joining to dimension tables
- The summary metrics in `fct_event_rsvp_summary` are derived from the granular data in `fct_event_rsvps`

This design supports both detailed analysis of individual RSVPs and high-level reporting on event engagement metrics. 