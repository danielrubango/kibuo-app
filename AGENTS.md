# kibuo

Android-first Flutter budgeting app, offline by default. The app's name is always lowercase: **kibuo**.

Start here: [docs/STATE.md](docs/STATE.md) says what is delivered, what is next, the open questions and the known pitfalls.

## Working with the owner

The owner does not read Dart, Kotlin or Swift; agents write the code. Report in French, in terms of behaviour the owner can try on the device. Tests and the owner's on-device check are the quality gate. How a step runs (questions first, walkthrough on the emulator, showing, merging) and the owner's standing rules: [docs/WORKING.md](docs/WORKING.md).

## Languages

Code, identifiers and commits in English. Product docs, ADRs, glossary and backlog in French. User-facing text goes through localization (French and English from day one).

## Rules of the codebase

- Domain logic lives in pure Dart with no Flutter import, so it is portable to iOS and web.
- Money is stored as integers in the currency's minor unit.
- Critical logic ships with automated tests written first: balances, conversions, recurrences, backup and restore, database migrations.
- Changing a table: bump `KibuoDatabase.currentSchema` in `lib/data/database.dart`, run `dart run drift_dev make-migrations`, and write the migration test against the saved schemas first.
- `tool/check.sh` runs formatting, analysis and tests; the pre-commit hook runs it.
- Every Android-only API or plugin gets a line in `docs/backlog/ios.md` in the same change.
- Validated design is the reference: any departure from a validated board, or any board whose logic looks wrong, is proposed to the owner and waits for an explicit yes. Measure the board before coding a screen.
- Never clear the app's data on the emulator without asking, except wiping a blocked emulator (see Commands). On the owner's phone, install as an update only; never uninstall.

## Git

One branch per feature, off `main`. Conventional Commits. Commit on the branch as soon as a step stands; run `git commit` on its own, read `git log -1` (the hook may refuse), and merge into `main` only after the owner has validated the step. The owner pushes `main` himself.

## Where to look

- [docs/STATE.md](docs/STATE.md): what is done, next, open, and the pitfalls already met.
- [docs/WORKING.md](docs/WORKING.md): the owner, the step cycle, the canvas method, the environment, the skills.
- [docs/PRODUCT.md](docs/PRODUCT.md): before building or changing any feature.
- [GLOSSARY.md](GLOSSARY.md): when naming a concept in code, UI or docs.
- [docs/design/SYSTEM.md](docs/design/SYSTEM.md): tokens, type, icons, the kit, patterns, tone of the texts.
- [docs/design/DIRECTION.md](docs/design/DIRECTION.md): visual rules with their dates, delivered screens and their boards, discarded variants.
- [docs/design/boards/](docs/design/boards/): the canvas boards, their state and the code that implements them.
- [docs/adr/](docs/adr/): before touching storage, currencies, backups, security or sync.
- [docs/backlog/](docs/backlog/): when a request belongs after the V1, or to record one that does.
- [docs/ROADMAP.md](docs/ROADMAP.md): the phases and their boxes.

## Commands

Flutter 3.47.9 (stable), Dart 3.13.7, installed with fvm globally (`~/fvm/default/bin` on the PATH; no `.fvm` folder in the repo).

```bash
git config core.hooksPath .githooks
```

```bash
tool/check.sh
```

```bash
flutter gen-l10n
```

After adding text to `lib/l10n/app_fr.arb` (the source) and `app_en.arb` (every key translated).

```bash
dart run build_runner build --delete-conflicting-outputs
```

After changing a Drift table or query; then, for a schema change:

```bash
dart run drift_dev make-migrations
```

Emulator (AVD `Pixel_10_Kibuo`, in English, `emulator-5554`):

```bash
~/Library/Android/sdk/emulator/emulator -avd Pixel_10_Kibuo -no-snapshot-save &
```

Build and install on the emulator, then, after the walkthrough, on the owner's phone (Poco X3 NFC, `abe5999d`). With both connected, every `adb` command takes `-s`.

```bash
flutter build apk --profile
```

```bash
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-profile.apk
```

```bash
adb -s abe5999d install -r build/app/outputs/flutter-apk/app-profile.apk
```

No test Android user any more: `kibuo-essai` was removed on 25 November 2026 to free the emulator. To try a first launch without touching the main profile, create one for the occasion, then remove it (two running users saturate the emulator):

```bash
adb -s emulator-5554 shell pm create-user kibuo-essai
```

```bash
adb -s emulator-5554 shell pm remove-user <id>
```

If the emulator keeps blocking after a restart, the owner allows wiping it (`emulator -avd Pixel_10_Kibuo -wipe-data`), even though its data is lost (25 November 2026).

Restarting a saturated emulator, unlocking a test user, pushing a file to it: [docs/STATE.md](docs/STATE.md#émulateur-et-android).

## Skills

Claude Code skills live on the owner's computer (`~/.claude/skills/`), except `/next-step`, which is in this repo (`.claude/skills/next-step/`). What each one does, so another agent can follow the same method: [docs/WORKING.md](docs/WORKING.md#skills).
