# 05: Rails parity and POC evaluation

**What to build:** Evidence that the POC reproduces the current Rails user journey closely enough to evaluate the rewrite, without introducing production migration work.

**Blocked by:** 01: TypeScript POC foundation; 02: Seed data and team search; 03: Upcoming race display; 04: Live Cyclingflash startlists and rider matching.

**Status:** ready-for-agent

- [ ] Representative Rails and POC responses are compared.
- [ ] Search, race selection, date formatting, rider matching, links, messages, and failure behavior are covered.
- [ ] Rendered structure and screenshots are compared as visual regression signals.
- [ ] The seed and reseed lifecycle is verified against the active CSV files.
- [ ] Local setup and live-scraping prerequisites are documented.
- [ ] Differences from Rails are recorded as defects or explicitly justified POC limitations.
- [ ] No production service, hostname, database, or credentials are changed.
