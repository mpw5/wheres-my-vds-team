# TypeScript rewrite proof of concept

## Problem Statement

The current application is a Rails application that helps a user find their VDS team by searching for a team name or directeur sportif. It lists upcoming races and checks live race startlists to identify which riders from the selected team are starting.

The team wants to evaluate whether the application could be rewritten in TypeScript without changing how it looks or behaves. This is an isolated proof of concept, not a commitment to replace the Rails application in production. The POC must therefore demonstrate credible behavioral and visual parity while remaining disposable and independent of the existing service.

## Solution

Build an isolated TypeScript/Next.js proof of concept that serves the current user journey as server-rendered HTML. It will use a disposable SQLite database seeded from the active team and race CSV files, preserve the current search and display behavior, and make actual live scraping calls to Cyclingflash for race startlists.

The current Rails application remains the behavioral oracle. The POC will be compared against representative Rails responses and domain outcomes, but it will not modify the Rails application, its deployment, its hostname, its database, or its production credentials.

Live Cyclingflash requests are part of the POC runtime. Test fixtures may be used to exercise HTML parsing and scraper failure handling deterministically, but the running POC must not substitute fixture data for the live scraper.

## User Stories

1. As a cycling fan, I want to open the POC at the root URL, so that I can use the same entry point as the current application.
2. As a cycling fan, I want to see the current page heading and links, so that the POC feels like the existing application.
3. As a cycling fan, I want to search using a team name, so that I can find the relevant VDS team.
4. As a cycling fan, I want to search using a directeur sportif name, so that I can find the relevant VDS team without knowing the team name.
5. As a cycling fan, I want searches to ignore leading and trailing whitespace, so that accidental spaces do not prevent a match.
6. As a cycling fan, I want searches to be case-insensitive, so that capitalization does not affect the result.
7. As a cycling fan, I want partial searches to match a substring of a team name or directeur sportif name, so that I do not need to enter the full value.
8. As a cycling fan, I want the search to use the same query parameter as the current application, so that existing links and browser behavior remain compatible.
9. As a cycling fan, I want no-results searches to show the existing no-teams message, so that an unsuccessful search is clear.
10. As a cycling fan, I want matching teams grouped by team type, so that male and female results remain understandable.
11. As a cycling fan, I want each matching team to show its team name and directeur sportif, so that I can confirm I selected the right team.
12. As a cycling fan, I want to see upcoming races for each matching team type, so that I can identify relevant races.
13. As a cycling fan, I want races ordered by their start date, so that the nearest races appear first.
14. As a cycling fan, I want no more than the current number of upcoming races shown per team type, so that the page remains focused and consistent with the Rails application.
15. As a cycling fan, I want each race to show its current date format, so that single-day and multi-day races are easy to understand.
16. As a cycling fan, I want each race name to link to its current Cyclingflash startlist URL, so that I can inspect the source startlist.
17. As a cycling fan, I want the POC to fetch actual current startlists from Cyclingflash, so that the displayed rider information reflects live external data.
18. As a cycling fan, I want the page to remain available when Cyclingflash cannot be reached, so that a temporary external outage does not prevent team searches.
19. As a cycling fan, I want cached startlist data used when a refresh fails, so that previously available rider information is not unnecessarily lost.
20. As a cycling fan, I want the page to show that no riders were found when no matching riders are available, so that an empty result is explicit.
21. As a cycling fan, I want matching riders displayed using the current normalization behavior, so that minor naming differences between VDS and Cyclingflash do not hide a match.
22. As a maintainer, I want the POC to seed teams and races from the active CSV files, so that the experiment uses the same current source data as Rails.
23. As a maintainer, I want the POC database to be disposable, so that experiments cannot damage production data.
24. As a maintainer, I want the POC to prefetch upcoming startlists on startup on a best-effort basis, so that the first page request is usually fast without making Cyclingflash availability a deployment prerequisite.
25. As a maintainer, I want live scraping to be replaceable at the parser and failure-handling boundary in tests, so that scraper behavior can be verified without making every test depend on the network.
26. As a maintainer, I want the POC to run locally with documented commands, so that the experiment can be evaluated and discarded independently of Rails.
27. As an evaluator, I want the POC to preserve the current visual structure, typography, wording, links, and interaction model, so that I can judge the rewrite rather than a redesign.
28. As an evaluator, I want parity checks against representative Rails behavior, so that apparent similarities are supported by evidence.
29. As an operator, I want scraper failures logged without exposing unnecessary internal details to users, so that the POC remains diagnosable while preserving the current user experience.
30. As a project owner, I want the POC isolated from the existing Render service and public hostname, so that evaluation cannot disrupt the current application.

## Implementation Decisions

- Use TypeScript with Next.js and server-rendered pages. Do not introduce a client-heavy single-page application where the current Rails application does not require one.
- Use a disposable SQLite database behind a typed data-access boundary.
- Treat the active team and race CSV files as authoritative runtime seed data. Historical season files remain reference material and are not loaded initially.
- Seed the database deterministically for the POC. The POC may explicitly recreate its disposable database; it must not connect to or alter the Rails production database.
- Model a team with one name, one directeur sportif, one team type, and its stored rider collection. Preserve the source field semantics while exposing the domain term directeur sportif in user-facing behavior and documentation.
- Interpret the `team_ds` query as a trimmed, case-insensitive substring search against either the team name or directeur sportif. It does not search riders.
- Display up to ten upcoming races for each matching team type, ordered by start date and filtered from the current date.
- Preserve the current single-day and multi-day date formatting, race naming, external links, page wording, HTML structure, typography, styling hooks, and no-results messages unless a difference is required by Next.js rendering.
- Implement a dedicated live Cyclingflash scraper and parser. The running POC must make actual HTTP requests to Cyclingflash for startlists and must not use canned startlist fixtures as its runtime data source.
- Keep the current lazy refresh behavior: a missing or stale startlist may trigger a live fetch, while a failed fetch leaves the page available and preserves usable cached data.
- Keep startup prefetching of upcoming male and female races as best effort. A Cyclingflash outage must not prevent the POC from starting.
- Preserve the current rider normalization and matching semantics, including transliteration, lowercasing, apostrophe removal, hyphen replacement, parenthesis removal, whitespace squeezing, and the existing partial-word comparison behavior.
- Keep the POC deployment-independent from the existing Render service. Local execution is required; an isolated preview deployment is optional and must not modify the existing service.
- Do not add production migration, cutover, dual-write, or Rails retirement work. This is an experiment only.
- Do not redesign the domain model beyond what is necessary to reproduce the current user journey.

## Testing Decisions

- Prefer the highest practical seam: the rendered HTTP response at the root URL, using a disposable seeded database and a controllable scraper dependency. Assert externally visible behavior rather than framework internals.
- Add request-level parity tests for empty searches, exact team-name searches, directeur sportif searches, case variation, whitespace padding, partial matches, unknown searches, grouping, race ordering, date formatting, links, wording, and no-results behavior.
- Add live-scraper integration coverage for the POC path where the application makes an actual Cyclingflash request. This verifies that the deployed/runtime scraper is genuinely used rather than silently returning fixture data.
- Keep deterministic parser tests using representative HTML fixtures. These fixtures test extraction rules and malformed/changed HTML handling only; they are not a substitute for live scraping in the running POC.
- Test live-network failure handling through a controllable transport or service boundary, asserting that the page remains available and that cached or empty startlist behavior matches the current application.
- Test team matching at the user-visible behavior boundary, including accent, punctuation, hyphen, apostrophe, parenthesis, and whitespace normalization cases represented by the current data.
- Test race selection at the user-visible behavior boundary, including current-date filtering, start-date ordering, team-type grouping, and the ten-race limit.
- Verify the seed process against the active CSV files and confirm that a fresh POC database contains the expected teams and races without requiring Rails.
- Compare representative POC responses and domain outcomes with the Rails application as the behavioral oracle. Include screenshot or rendered-structure comparisons as regression signals, while allowing harmless browser rendering differences.
- Preserve the style of existing Rails request, model, and scraper specs as prior art, while moving the POC coverage to the equivalent TypeScript/Next.js HTTP, data, and scraper boundaries.

## Out of Scope

- Replacing or modifying the Rails application.
- Production cutover, Rails retirement, dual writes, or migration of the current Render service.
- Changing the public hostname, production deployment, production database, or production credentials.
- Loading historical season CSVs into the active POC dataset.
- Replacing SQLite with PostgreSQL.
- Redesigning the visual experience or changing user-facing wording and links without a parity justification.
- Adding user accounts, authentication, administration, or new product capabilities.
- Building a client-side SPA where server-rendered behavior is sufficient.
- Making Cyclingflash a hard dependency for startup or page availability.
- Using fixture startlists as the runtime behavior of the POC.
- Treating live external integration tests as the only form of scraper testing; deterministic parser tests remain necessary.
- Broad production observability, performance optimization, or security hardening beyond what is needed for a safe isolated experiment.

## Further Notes

The current Rails entrypoint runs database preparation and seeding, but the deployed SQLite file is disposable when no persistent Render disk is configured. The POC should make that lifecycle explicit rather than relying on incidental container replacement.

The Rails application remains the comparison oracle throughout the experiment. Any behavior that differs should be recorded as either an accidental parity defect or an explicitly justified POC limitation.

Actual Cyclingflash requests may be affected by network availability, rate limits, robots policies, or upstream HTML changes. The POC should identify those conditions clearly in logs and preserve page availability where possible.
