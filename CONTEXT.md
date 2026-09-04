# Domain Context

## Season

A cycling competition period represented by the repository's season-specific source files. The active `teams.csv` and `races.csv` files define the data used by the current application; historical season files are retained as reference data and are not loaded into the active experience.

## Team

A VDS team with one team name, one directeur sportif, and a set of riders. The current data source represents the directeur sportif in the `ds` field.

## Directeur sportif

The person associated with a team in the `ds` field. A user's `team_ds` search query matches a team's directeur sportif or team name.

## Team search

A search submitted through the `team_ds` query. It is trimmed, case-insensitive, and uses substring matching against either the team's directeur sportif or its name. It does not search rider names.

## Race

An event with a race type, name, PCS name, start date, and end date. The application displays up to ten upcoming races for each team type, ordered by start date.

## Startlist

The rider names scraped from Cyclingflash for a race. A startlist is derived external data and may be cached temporarily; it is not authoritative seed data.

## Rider matching

The comparison between a team's stored rider names and a race startlist. Matching normalizes accents, case, apostrophes, hyphens, parentheses, and repeated whitespace before comparing names.

## VDS and PCS

VDS is the application's cycling competition data source and PCS is the reference naming source used for races and riders. The application links displayed races to Cyclingflash using their PCS name.

## Proof of concept

The TypeScript rewrite is an isolated experiment, not a production migration. It should demonstrate the current user journey and behavior without changing the Rails application, its deployment, its hostname, its database, or its production credentials.
