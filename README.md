<div align="center">

# 🔮 NewsCrystal

**A fast tech-news scraper and aggregator, written in [Crystal](https://crystal-lang.org).**

Follow Hacker News, Dev.to and Lobsters from a single feed — browsable on the web,
queryable through a REST API, and subscribable via RSS.

[![CI](https://github.com/Laki0s/NewsCrystal/actions/workflows/ci.yml/badge.svg)](https://github.com/Laki0s/NewsCrystal/actions/workflows/ci.yml)
[![Valgrind](https://github.com/Laki0s/NewsCrystal/actions/workflows/valgrind.yml/badge.svg)](https://github.com/Laki0s/NewsCrystal/actions/workflows/valgrind.yml)
[![Crystal](https://img.shields.io/badge/crystal-%3E%3D1.10-black?logo=crystal)](https://crystal-lang.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

</div>

---

## Why NewsCrystal?

Keeping up with tech means juggling half a dozen tabs. NewsCrystal scrapes those
sources on a schedule, deduplicates the articles, and serves everything from one
place — a clean web page, a JSON API, or your favorite RSS reader.

It doubles as a hands-on tour of Crystal: static typing, fiber-based concurrency,
and the shards ecosystem.

## Features

- 📰 **Multi-source aggregation** — Hacker News, Dev.to and Lobsters behind a
  single `Source` interface.
- 🧹 **Automatic deduplication** — a URL-derived hash keeps the feed clean across
  runs.
- ⏱️ **Scheduled scraping** — a background fiber refreshes every source every
  15 minutes, resilient to network failures.
- 🔌 **REST API** — paginated, filterable access to the aggregated articles.
- 🖥️ **Web interface** — lightweight HTML/CSS/JS, sortable and searchable.
- 📡 **RSS/Atom feed** — subscribe from any reader (`/feed.xml`).
- 🐳 **Container-ready** — ships with a Dockerfile for VPS deployment.

## Tech stack

| Layer | Choice |
|-------|--------|
| Language | Crystal (`>= 1.10`) |
| Web / API | [Kemal](https://kemalcr.com) |
| HTML parsing | [lexbor](https://github.com/kostya/lexbor) |
| Database | SQLite via [crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) |
| Concurrency | Crystal fibers (periodic scraping) |
| Linting | [Ameba](https://github.com/crystal-ameba/ameba) |
| CI | GitHub Actions (self-hosted) — format, lint, build, specs, Valgrind |

## Architecture

```
                +------------------+
   sources ---> |     Scraper      |  HTTP fetch + lexbor HTML parsing
  (HN, Dev.to,  |  (Source impls)  |
   Lobsters)    +--------+---------+
                         | Article
                         v
                +------------------+
                |     Storage      |  SQLite + URL-hash deduplication
                +--------+---------+
                         |
              +----------+-----------+
              v                      v
      +---------------+      +----------------+
      |   REST API    |      |   RSS/Atom     |   Kemal HTTP layer
      | /articles     |      |   /feed.xml    |
      +-------+-------+      +----------------+
              ^
              | fetch (JSON)
      +-------+-------+
      | Web interface |  HTML/CSS/vanilla JS
      +---------------+

  A scheduler fiber re-runs the scraper for every source every 15 minutes.
```

## Requirements

- Crystal `>= 1.10` and Shards ([install guide](https://crystal-lang.org/install/))
- SQLite development headers — `libsqlite3-dev` on Ubuntu/Debian
- (optional) Docker, for the containerized deployment

## Getting started

```bash
# 1. Clone
git clone git@github.com:Laki0s/NewsCrystal.git
cd NewsCrystal

# 2. Install dependencies
shards install

# 3. Run the test suite
crystal spec

# 4. Build and run
shards build
./bin/news_crystal
```

## Configuration

Configuration is read from environment variables (a `.env` file is supported).

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Port the HTTP server listens on |
| `DATABASE_PATH` | `./news_crystal.db` | Path to the SQLite database file |
| `SCRAPE_INTERVAL` | `900` | Seconds between scraping runs (default 15 min) |
| `HTTP_TIMEOUT` | `10` | Per-request HTTP timeout in seconds |

> Configuration options land alongside their features (US5, US9). See the
> roadmap below for current status.

## API

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/articles` | List articles — paginated (`?page`, `?per_page`), filterable (`?source`) |
| `GET` | `/articles/:id` | Fetch a single article by id |
| `GET` | `/feed.xml` | Aggregated RSS 2.0 feed |

Example:

```bash
curl "http://localhost:3000/articles?source=hackernews&per_page=10"
```

## Development

```bash
crystal tool format          # auto-format the code
crystal tool format --check  # verify formatting (CI)
./bin/ameba                  # lint
crystal spec                 # run specs
```

Every push and pull request runs the **self-hosted** GitHub Actions pipeline:
formatting, Ameba, release build, specs, and a Valgrind memory check.

Issue and PR templates live in [`.github/`](.github/); contribution workflow and
branch naming follow the User Stories (see below).

## Project structure

```
src/
  news_crystal.cr        # Library entry point (wires the components together)
  news_crystal/
    version.cr           # VERSION constant
  scraper/               # HTTP fetching + HTML parsing of the sources
    scraper.cr
    source.cr            # Common Source interface
  storage/               # SQLite persistence + deduplication
    storage.cr
    article.cr           # Article domain model
  api/                   # REST API (Kemal) + RSS/Atom feed
    api.cr
  web/                   # Static assets for the web interface
spec/                    # Specs
.github/                 # Issue/PR templates and self-hosted CI workflows
```

## Roadmap

Development follows the ten User Stories of the specification
(`cahier_des_charges_NewsCrystal.pdf`), tracked in [`Issues.md`](Issues.md).

- [x] **US1** — Project & Crystal environment setup
- [ ] **US2** — Hacker News scraper
- [ ] **US3** — Storage & deduplication (SQLite)
- [ ] **US4** — Additional sources (Dev.to, Lobsters)
- [ ] **US5** — Automatic scraping scheduling
- [ ] **US6** — REST API (Kemal)
- [ ] **US7** — Web browsing interface
- [ ] **US8** — RSS/Atom export
- [ ] **US9** — Robustness & error handling
- [ ] **US10** — Deployment & documentation

> **Status:** early development — the project structure is in place (US1). The
> features above are being implemented one User Story at a time.

## Contributing

1. Pick a User Story / issue and branch from `main`: `feature/US<n>-<slug>`.
2. Keep the build green: `crystal tool format`, `./bin/ameba`, `crystal spec`.
3. Open a pull request using the template and link the issue (`Closes #n`).

## License

Released under the [MIT License](LICENSE).
