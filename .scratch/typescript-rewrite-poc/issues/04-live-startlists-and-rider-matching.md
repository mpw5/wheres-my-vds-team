# 04: Live Cyclingflash startlists and rider matching

**What to build:** The running POC makes actual HTTP requests to Cyclingflash, identifies selected-team riders in live startlists, and remains usable when the external service fails.

**Blocked by:** 03: Upcoming race display.

**Status:** resolved

- [ ] Runtime startlist requests use live Cyclingflash responses, not fixture data.
- [ ] Missing or stale startlists trigger a live refresh.
- [ ] Matching riders use the current normalization behavior.
- [ ] Matching riders and the “No riders found” state match current behavior.
- [ ] Cached data is retained when a refresh fails.
- [ ] A failed or unavailable scraper does not prevent the page from rendering.
- [ ] Startup prefetching is best effort and does not block application availability.
- [ ] Parser tests use HTML fixtures only for deterministic extraction and malformed-response cases.
- [ ] A live integration check demonstrates that the runtime path performs an actual Cyclingflash request.
