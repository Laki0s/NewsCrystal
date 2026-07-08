# NewsCrystal — Issues

Ten issues, one per User Story from the specification. Copy each block into
**GitHub → Issues → New issue → 📋 Task / User Story**, then set the matching
**Type** and **Labels** listed at the bottom of this file.

---

## #1 — US1: Project and Crystal environment setup

- **Type:** Task
- **Labels:** `setup`, `priority:high`
- **Estimate:** 0.5 day

**Objective**
Set up a working Crystal environment and a clear project structure.

**Acceptance criteria**
- [ ] Crystal and Shards installed and documented (versions pinned)
- [ ] `shard.yml` initialized (name, targets, dependencies, dev-dependencies)
- [ ] Folder structure created: `src/scraper`, `src/storage`, `src/api`, `src/web`
- [ ] `.gitignore` for Crystal (`/lib`, `/bin`, `*.dwarf`, `.env`, `*.db`)
- [ ] Ameba added as a dev dependency and runnable via `./bin/ameba`
- [ ] Project compiles with `shards build`

**Technical notes**
Base for every other US. Add `lexbor`, `kemal`, `sqlite3` and `ameba` to `shard.yml`.

---

## #2 — US2: Hacker News scraper

- **Type:** Feature
- **Labels:** `scraper`, `priority:high`
- **Estimate:** 1.5 day

**Objective**
Automatically fetch the latest articles published on Hacker News.

**Acceptance criteria**
- [ ] HTTP module that fetches the Hacker News front page
- [ ] HTML parsing (via `lexbor`) extracting: title, link, author, publication date
- [ ] Results mapped to an `Article` model
- [ ] Handles missing fields gracefully (never crashes on a malformed row)
- [ ] Unit spec covering parsing against a saved HTML fixture

**Technical notes**
Keep parsing selectors isolated so a site HTML change is easy to patch. HN also
exposes an official Firebase API — worth discussing as a robustness fallback.

---

## #3 — US3: Storage and deduplication (SQLite)

- **Type:** Feature
- **Labels:** `storage`, `priority:high`
- **Estimate:** 1 day

**Objective**
Store fetched articles without duplicates.

**Acceptance criteria**
- [ ] SQLite database via `crystal-sqlite3`
- [ ] `articles` table: `id`, `title`, `url`, `source`, `date`, `hash`
- [ ] Hash computed from the link to detect duplicates
- [ ] Inserting an already-known article is ignored (no duplicate rows)
- [ ] Migration / schema creation runs automatically on startup
- [ ] Spec covering insert + deduplication

**Technical notes**
Unique index on `hash`. Decide hash algorithm (e.g. SHA256 of the normalized URL).

---

## #4 — US4: Additional sources (Dev.to, Lobsters)

- **Type:** Feature
- **Labels:** `scraper`, `priority:medium`
- **Estimate:** 1.5 day

**Objective**
Aggregate articles coming from several different sources.

**Acceptance criteria**
- [ ] Common `Source` interface / abstract type generalizing the scraper
- [ ] Hacker News scraper refactored to implement `Source`
- [ ] Dev.to scraper implemented
- [ ] Lobsters scraper implemented
- [ ] Each source tagged so articles keep their origin
- [ ] Specs for the two new scrapers (HTML fixtures)

**Technical notes**
Depends on #2. The `Source` abstraction isolates per-site HTML fragility.

---

## #5 — US5: Automatic scraping scheduling

- **Type:** Feature
- **Labels:** `scheduler`, `priority:medium`
- **Estimate:** 1 day

**Objective**
Refresh all sources automatically at a regular interval.

**Acceptance criteria**
- [ ] Scheduled loop (Crystal fiber + `sleep`) re-running all sources every 15 min
- [ ] Interval configurable (env var / config)
- [ ] Network errors handled (timeout, source unavailable) without stopping the loop
- [ ] Each run logged (started, per-source result, new articles count)

**Technical notes**
Depends on #4. Run scraping in a background fiber so it does not block the API.

---

## #6 — US6: REST API (Kemal)

- **Type:** Feature
- **Labels:** `api`, `priority:high`
- **Estimate:** 1 day

**Objective**
Expose the aggregated articles through a REST API.

**Acceptance criteria**
- [ ] `GET /articles` — paginated list, filterable by source
- [ ] `GET /articles/:id` — single article
- [ ] JSON responses with proper content-type and status codes
- [ ] 404 returned for an unknown id
- [ ] Specs covering both routes (list, filter, pagination, not-found)

**Technical notes**
Depends on #3. Use Kemal. Define pagination params (`page`, `per_page`).

---

## #7 — US7: Web browsing interface

- **Type:** Feature
- **Labels:** `web`, `priority:medium`
- **Estimate:** 2 days

**Objective**
Let end users browse the aggregated articles in a simple interface.

**Acceptance criteria**
- [ ] Web page (HTML/CSS/light JS) consuming the REST API
- [ ] Articles displayed sorted by date
- [ ] Filter by source
- [ ] Keyword search bar
- [ ] Responsive, readable layout

**Technical notes**
Depends on #6. Vanilla JS (no framework) as required by the spec.

---

## #8 — US8: RSS/Atom export

- **Type:** Feature
- **Labels:** `rss`, `priority:medium`
- **Estimate:** 1 day

**Objective**
Let readers subscribe to the aggregated feed from their own RSS reader.

**Acceptance criteria**
- [ ] `GET /feed.xml` route generating the aggregated feed
- [ ] Valid RSS 2.0 (validates in an RSS validator)
- [ ] Correct content-type (`application/rss+xml`)
- [ ] Feed reflects the latest aggregated articles
- [ ] Spec asserting well-formed XML and required elements

**Technical notes**
Depends on #6. Consider Atom too; RSS 2.0 is the required standard.

---

## #9 — US9: Robustness and error handling

- **Type:** Task
- **Labels:** `reliability`, `tests`, `priority:high`
- **Estimate:** 1 day

**Objective**
Keep working even if a source is temporarily unavailable.

**Acceptance criteria**
- [ ] Timeouts on all HTTP requests
- [ ] Error logging across scraper and storage
- [ ] Retry logic on transient network failures
- [ ] Automated tests on the scraping and storage modules
- [ ] A failing source never crashes the whole aggregation run

**Technical notes**
Cross-cutting; touches #2, #4, #5. Define retry count/backoff.

---

## #10 — US10: Deployment and documentation

- **Type:** Task
- **Labels:** `deployment`, `documentation`, `priority:medium`
- **Estimate:** 0.5 day

**Objective**
Deploy and document the application so it can be reused or consulted easily.

**Acceptance criteria**
- [ ] `Dockerfile` building and running the app
- [ ] App deployed on the Ubuntu VPS and reachable
- [ ] `README` covering install, source configuration and launch
- [ ] Environment/config variables documented

**Technical notes**
Depends on the app being functional. Target OS: Linux (Ubuntu).

---

## Labels to create

| Label | Color | Purpose |
|---|---|---|
| `setup` | `#ededed` | Project/environment setup |
| `scraper` | `#0e8a16` | Scraping modules |
| `storage` | `#5319e7` | Database / persistence |
| `scheduler` | `#1d76db` | Periodic scheduling (fibers) |
| `api` | `#fbca04` | REST API (Kemal) |
| `web` | `#d93f0b` | Web interface |
| `rss` | `#f9d0c4` | RSS/Atom feed |
| `reliability` | `#b60205` | Robustness / error handling |
| `tests` | `#c2e0c6` | Automated tests |
| `deployment` | `#0052cc` | Docker / VPS |
| `documentation` | `#0075ca` | Docs / README |
| `priority:high` | `#b60205` | Must be done early |
| `priority:medium` | `#fbca04` | Normal priority |
| `priority:low` | `#c2e0c6` | Nice to have |
| `blocked` | `#000000` | Waiting on another issue |
| `good first issue` | `#7057ff` | Easy entry point |

> `bug`, `enhancement` and `triage` already come from the issue templates —
> keep them too.

## Issue Types to create

GitHub Issue Types (repo/org setting, **Settings → Issues → Types**). Three are
enough for this project:

| Type | Used for |
|---|---|
| **Feature** | New functionality (US2, US3, US4, US5, US6, US7, US8) |
| **Task** | Setup / cross-cutting / ops work (US1, US9, US10) |
| **Bug** | Regressions reported later (from the bug_report template) |

---
---

# Pull Requests

Ready-to-paste PR descriptions, following `.github/PULL_REQUEST_TEMPLATE.md`.

---

## PR — US1: Project and Crystal environment setup

**Branch:** `feature/US1-project-setup` → `main`

### Description

Bootstraps the NewsCrystal project: Crystal manifest, dependency declarations,
the `scraper / storage / api / web` source layout, tooling (Ameba, EditorConfig,
`.gitignore`) and a first passing spec. No runtime behavior yet — this PR is the
foundation every following User Story builds on.

Highlights:

- **`shard.yml`** with the target and the dependencies from the spec
  (`kemal`, `lexbor`, `sqlite3`) plus `ameba` as a dev dependency.
- **Source layout** with a module per component and two forward-looking
  abstractions already in place:
  - `NewsCrystal::Storage::Article` — the shared domain model (US3 table shape).
  - `NewsCrystal::Scraper::Source` — the abstract interface every scraper will
    implement (prepares US2/US4).
- **Specs** so CI has a green run from day one.
- **Docs**: full `README` (overview, architecture, setup) and `LICENSE` (MIT).

```crystal
# src/scraper/source.cr — the contract every source scraper will satisfy
module NewsCrystal
  module Scraper
    abstract class Source
      # Human-readable identifier stored on each article (e.g. "hackernews").
      abstract def name : String

      # Fetches and parses the latest articles for this source.
      abstract def fetch : Array(Storage::Article)
    end
  end
end
```

```crystal
# src/storage/article.cr — shared model, mirrors the future SQLite table (US3)
struct NewsCrystal::Storage::Article
  getter title : String
  getter url : String
  getter source : String
  getter published_at : Time
  getter url_hash : String # URL fingerprint (maps to the `hash` column, US3)
end
```

### Related User Story / Issue

Closes #1 — US1: Project and Crystal environment setup

### Type of change

- [x] ✨ New feature (initial project scaffolding)
- [ ] 🐛 Bug fix
- [ ] ♻️ Refactoring (no behavior change)
- [x] 📖 Documentation
- [x] 🧪 Tests
- [x] 🔧 Configuration / CI / deployment

### How to test

```bash
shards install
crystal spec                 # 2 examples, 0 failures
crystal tool format --check  # formatting is clean
./bin/ameba                  # no lint offenses
shards build                 # produces bin/news_crystal
```

Expected spec output:

```
NewsCrystal
  exposes a version

NewsCrystal::Storage::Article
  builds an article with its fields

Finished in X ms
2 examples, 0 failures, 0 errors, 0 pending
```

### Checklist

- [x] The code compiles (`crystal build`)
- [x] Formatting passes (`crystal tool format --check`)
- [x] The linter passes (`ameba`)
- [x] The specs pass (`crystal spec`)
- [x] I have added / updated tests where needed
- [x] I have updated the documentation (README) where needed

### Screenshots / notes

- Acceptance criteria of issue #1 (structure, `shard.yml`, `.gitignore`,
  Ameba, compiles) are all covered.
- Runtime entry point is intentionally empty; the app boot lands with the
  scheduler and API (US5/US6).
- **CI note:** the self-hosted runner must provide `crystal`, `shards`,
  `ameba` and `valgrind` on the `PATH` for the workflows to pass.
