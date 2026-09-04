# 02: Seed data and team search

**What to build:** A user can search the active VDS data by team name or directeur sportif and see matching teams using the current page structure and messages.

**Blocked by:** 01: TypeScript POC foundation.

**Status:** resolved

- [ ] Active team CSV data seeds the disposable database.
- [ ] The `team_ds` query searches team name and directeur sportif.
- [ ] Search matching is trimmed, case-insensitive, and substring-based.
- [ ] The search does not match rider names.
- [ ] Empty and unknown searches match the current Rails behavior.
- [ ] Matching team name and directeur sportif values are displayed as in the current application.
- [ ] Request-level tests cover the complete search flow.
