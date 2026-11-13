# Kibuo

Android-first Flutter budgeting app, offline by default. Roadmap state: `docs/ROADMAP.md`.

## Working with the owner

The owner does not read Dart, Kotlin or Swift; agents write the code. Report in French, in terms of behaviour the owner can try on the device. Tests and the owner's on-device check are the quality gate.

## Languages

Code, identifiers and commits in English. Product docs, ADRs, glossary and backlog in French. User-facing text goes through localization (French and English from day one).

## Rules of the codebase

- Domain logic lives in pure Dart with no Flutter import, so it is portable to iOS and web.
- Money is stored as integers in the currency's minor unit.
- Critical logic ships with automated tests written first: balances, conversions, recurrences, backup and restore, database migrations.
- `tool/check.sh` runs formatting, analysis and tests; the pre-commit hook runs it once `git config core.hooksPath .githooks` is set in the clone.
- Every Android-only API or plugin gets a line in `docs/backlog/ios.md` in the same change.

## Git

One branch per feature, off `main`. Conventional Commits. Commit and merge after the owner has validated the step.

## Where to look

- `docs/PRODUCT.md`: before building or changing any feature.
- `GLOSSARY.md`: when naming a concept in code, UI or docs.
- `docs/adr/`: before touching storage, currencies, backups, security or sync.
- `docs/backlog/`: when a request belongs after the V1, or to record one that does.
- `/next-step`: the repeatable cycle for delivering a roadmap step.
