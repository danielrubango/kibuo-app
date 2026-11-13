---
name: next-step
description: Deliver the next Kibuo roadmap step through the project's repeatable cycle.
disable-model-invocation: true
---

# Next step

Deliver one roadmap step, the same way every time. Speak to the owner in French, in terms of what they can see and try. If the owner names a step in the arguments, take that one.

## 1. Orient

Read `docs/ROADMAP.md` (or the GitHub issues once `docs/backlog/github.md` has been carried out) and take the first unchecked step. Read the matching section of `docs/PRODUCT.md`, the ADRs that touch it, and `GLOSSARY.md`.

Done when you can state the step and what the owner will be able to check at the end, in two sentences, and any gap in the product docs has been put to the owner as a question.

## 2. Branch

From an up-to-date `main` with a clean tree, run `git switch -c <type>/<slug>`, where type is `feat`, `fix`, `docs`, `design` or `chore`.

Done when the new branch is checked out.

## 3. Prove

For critical logic (balances, conversions, recurrences, backup and restore, migrations), write the test first and watch it go _red_ for the expected reason. For interface work, write the on-device checklist. For design work, list the screens and states to be shown.

Done when every behaviour in the step has a red test, a checklist line or a listed state.

## 4. Build

Implement the step with the glossary's names, domain logic in pure Dart. Run `tool/check.sh`.

Done when both pass with no new warnings, or for design work when every listed state is rendered.

## 5. Show

Run the app on the emulator and exercise the step yourself. Hand the owner a short checklist to try on their phone (Poco X3 NFC), or the mockups to review.

Done when you have seen it work, and the owner has confirmed it or asked for changes. Requested changes return to step 3.

## 6. Record

- Tick the step in the roadmap.
- Update `docs/PRODUCT.md` when behaviour changed.
- Add new terms to `GLOSSARY.md`.
- Add an ADR for any decision that is hard to reverse, surprising without context, and the result of a real trade-off.
- Add every Android-only dependency to the register in `docs/backlog/ios.md`.
- Move anything out of scope to `docs/backlog/`.

Done when each line above has been applied or confirmed not to apply.

## 7. Commit

Propose a Conventional Commits message in English, commit once the owner approves, and merge into `main` once they have validated the step.

Done when the tree is clean and the owner knows which step comes next.
