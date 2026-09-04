# TypeScript POC

This is an isolated proof of concept for the Rails application. It is not connected to the existing service, deployment, hostname, database, or production credentials.

## Run locally

From this directory:

```sh
npm install
npx playwright install chromium
npm run dev
```

Open `http://localhost:3000/` and search by team name or directeur sportif using the `team_ds` field.

The POC reads the active seed data from the parent application and creates disposable SQLite data under `.data/`. Generated `.next/`, `.data/`, and `node_modules/` content is ignored. Chromium is required because Cyclingflash may return a Cloudflare challenge to plain HTTP clients; the scraper uses a headless browser fallback to load the rendered startlist.

## Validate

```sh
npm test
npm run build
```

Tests use local HTTP sources to keep parser and failure behavior deterministic. The running POC uses live Cyclingflash requests by default. Set `SCRAPER_BASE_URL` only when deliberately pointing the POC at a compatible local or test HTTP source.

## Parity checklist

Before treating the POC as evaluated:

- Compare the root page against the Rails page at an agreed desktop and mobile viewport.
- Check the heading, external links, search label, form behavior, result grouping, race dates, race links, rider output, and no-results messages.
- Run representative searches by team name, directeur sportif, mixed case, padded whitespace, partial value, and unknown value.
- Confirm live Cyclingflash requests are made and that a failed request leaves the page available.
- Recreate the disposable database from the active CSV files and confirm teams and races are available without Rails.
- Record any difference from Rails as either a defect or an explicitly accepted POC limitation.

The POC is not a production migration. Do not point it at production data or credentials, change the existing Render service, or retire the Rails application as part of this experiment.
