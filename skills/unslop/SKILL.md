---
name: unslop
description: Use before posting or committing prose a human will read — commit messages, issue/PR comments, store listing and "what's new" copy, wiki/Feature Map ux text, in-app help and error strings. Removes AI-sounding patterns. Leaves text you weren't asked to touch alone.
---

# Unslop

Adapted from cursor/plugins `unslop` (MIT), via michaelshimeles/skills.

Four passes: **scan → rewrite → add a voice → audit** ("what still sounds machine-made?") and fix what's left.

## Cut or replace

- **Puffery:** "robust", "seamless", "powerful", "pivotal", "testament to", "elevate", "unlock", "delve", "crucial", "leverage", "tapestry".
- **Inflated verbs:** "serves as" / "boasts" / "features" → "is" / "has".
- **Formulas:** "not just X but Y", reflexive groups of three, "-ing" tails ("…, ensuring a smooth experience"), a generic closing line, "I hope this helps".
- **Hedge stacks:** "may potentially help to" → "may help". Filler: "in order to" → "to", "utilize" → "use".
- **Vague sources:** "experts say", "users love". Name it or drop it.
- **Typography:** no em dashes in published copy. Use sentence-case headings, no decorative emoji, no bold on every noun, and straight quotes.

## Prefer

- A sentence that states a fact, a number, a mechanism or an instruction over one that states a feeling.
- Active voice with a named actor: "Sync uploads the outbox" rather than "the outbox is uploaded".
- Specific words for sailors: "anchor alarm sounds when the boat leaves the circle" rather than "stay safe at anchor".
- Varied sentence length. Take a position when one is warranted.

## SisuMate specifics

- Commit messages: imperative summary + issue number, then why, e.g. "Guard Uno AI timer with ref.mounted (#417)".
- Issue close comments: result line first (`verification-before-completion`), then files and blockers. No victory lap.
- Store copy (`marketing/`) and wiki ux text: the reader is a sailor, not a developer. No module or code names.
