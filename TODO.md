# Project TODOs and Future Improvements

## Data Modeling

- [ ] Think about implementing SCD Type 2 logic for dimensions that change over time (groups, venues, users)
- [ ] Add calendar dimension for standardized date analysis, dim_date

## CI/CD

- [ ] Lok at state:modified, implement to avoid unnecessary jobs;
- [ ] Look into implementing linting
- [ ] Implement Github pages to host documentation

## Performance Optimizations

- [ ] Improve incremental logic for fct_ tables, now we are fetching the whole dim table every run.

## Data Quality

- [ ] Think about adding data quality tests beyond null and uniqueness checks where useful
- [ ] Implement data freshness checks for source data, since it is not incremental now, havent done this
- [ ] Clean up staging table columns values even more

## Documentation

- [ ] Create documentation page accessible to end users

## Staging Model Improvements

### Events (stg_meetup__events)

1. Additional Event Improvements:
    - [ ] Add timezone handling for timestamps
    - [ ] Add validation for rsvp_limit vs actual RSVPs
    - [ ] Determine how to Distinguish recurring from single events

### Groups (stg_meetup__groups)

1. Description Analysis:
    - [ ] Consider text analysis in intermediate models:
        * Topic extraction from description
        * Sentiment analysis?

2. Additional Group Improvements:
    - [ ] Implement coordinate validation per city

### Users (stg_meetup__users)

1. Location Data Quality:
    - [ ] Implement country code standardization
    - [ ] Attempt to improve macro for cleaning hometown (clean_hometown) --> it doesn't clean everything properly, or use reference table, or geocoding

2. Additional User Improvements:
    - [ ] Add data quality tests for location fields

### Venues (stg_meetup__venues)

1. Venue Identity Issues:
    - [ ] Investigate source system to understand venue_id generation logic
    - [ ] Determine if different venue_ids for same name indicate branches or duplicates

2. Coordinate Inconsistencies:
    - [ ] Address venues with multiple coordinates
    - [ ] Handle (0,0) coordinates vs valid duplicates
    - [ ] Consider using geocoding service for validation

3. Name Variations:
    - [ ] Investigate multiple entries with identical data except venue_name
    - [ ] Understand venue_id significance in source system

4. City Data Quality:
    - [ ] Handly dirty cirty names properly by either improving macro for cleaning citry (clean_city) --> it doesn't clean everything properly, or using geocoding service, or reference table
