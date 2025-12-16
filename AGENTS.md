# Agent Handbook

## Purpose
Render structured JSON guitar tabs to ASCII with repeats, tuplets, palm mute / let ring rails, tie-to-previous sustain, tempo labels at measure starts, and optional metadata header banner.

## Default Flow for Changes
- Implement the code change (usually in `json_to_ascii_tab.rb`); keep defaults (4/4, standard tuning) intact.
- If behavior/output changes, update `doc/example.json` accordingly.
- Sync tests with fixtures: update `tests/example_test.rb` (or add tests) to assert new behavior.
- Run tests: `ruby -Itests tests/example_test.rb` plus other affected tests (`tests/interaction_test.rb`, `tests/signature_padding_test.rb`).
- Fix code/fixtures until tests pass.
- Refresh docs:
  - `README.md` (feature notes, rendered example snippet if output changed)
  - `doc/json_format-knowledge.md` (spec/semantics)
  - `doc/format.json.schema` (schema alignment)
- Stage, commit with `--no-gpg-sign`, and push to `origin` (`git@github.com:xpac27/json-to-ascii-tab.git`).

## Key Semantics
- `tie: true` ties **to previous note** on the same string; sustain gap rendered with `=`.
- Tempo automation: only `automations.tempo` entries at measure start (`position` 0/`nil`) render a left-aligned `Tempo <bpm>` label.
- Header banner: built from `name`, `instrument`, `partId` → `Name - Instrument (part N)` boxed with a blank line after.
- Measures enforce exact signature fill: pad with rest if short, clip if long; only `voices[0]` is rendered.

## Style/Notes
- ASCII only; keep comments minimal and meaningful.
- Repeat detection is content-based (canonicalized measures) up to 16 measures.
- Use `rg` for searching; avoid destructive git commands.

## Testing Quick Reference
- `ruby -Itests tests/example_test.rb`
- `ruby -Itests tests/interaction_test.rb`
- `ruby -Itests tests/signature_padding_test.rb`
