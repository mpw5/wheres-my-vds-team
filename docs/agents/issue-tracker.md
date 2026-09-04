# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file.
- Triage state is recorded as a `Status:` line near the top of each issue file.
- Comments and conversation history append to the bottom of the file under a `## Comments` heading.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/`, creating the directory if needed.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path.

## Wayfinding operations

- **Map**: `.scratch/<effort>/map.md`.
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, with a `Type:` line recording `research`, `prototype`, `grilling`, or `task`, and a `Status:` line recording `claimed` or `resolved`.
- **Blocking**: `Blocked by: NN, NN` near the top. A ticket is unblocked when every listed file is resolved.
- **Claim**: set `Status: claimed` and save before work.
- **Resolve**: append an `## Answer` heading, set `Status: resolved`, then add a context pointer to the map's Decisions-so-far.
