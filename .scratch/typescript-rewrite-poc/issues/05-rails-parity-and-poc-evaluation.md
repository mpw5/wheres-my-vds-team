# 05: Rails parity and POC evaluation

**What to build:** Evidence that the POC reproduces the current Rails user journey closely enough to evaluate the rewrite, without introducing production migration work.

**Blocked by:** 01: TypeScript POC foundation; 02: Seed data and team search; 03: Upcoming race display; 04: Live Cyclingflash startlists and rider matching.

**Status:** resolved

- [x] Representative Rails-visible behavior is covered at the root HTTP seam.
- [x] Search, race selection, date formatting, rider matching, links, messages, and failure behavior are covered.
- [x] The rendered page contract is protected by a parity test; screenshot comparison remains a manual evaluation step documented in the POC runbook.
- [x] The disposable seed lifecycle is exercised by the database and HTTP tests against the active CSV files.
- [x] Local setup and live-scraping prerequisites are documented.
- [x] Known differences are recorded as POC constraints: live network availability is external, and browser screenshots are regression signals rather than pixel equality.
- [x] No production service, hostname, database, or credentials were changed.

## Answer

The POC evaluation is complete. `npm test` passes all 10 tests and `npm run build` passes. The POC remains isolated from the Rails application and production infrastructure.
