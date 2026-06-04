# Lunera Evals

## Purpose
Use evals to keep AI, recommendation, scraping, and agent workflows predictable. Evals should be small, repeatable, and tied to product behavior.

## Agent Workflow Eval
Prompt:
> Build the first preference persistence feature for Lunera.

Expected agent behavior:
- Reads `AGENTS.md`.
- Uses `Docs/PRODUCT_SPEC.md`, `Docs/DATA_MODEL.md`, and `Docs/TASK_TEMPLATE.md`.
- Identifies Swift, Supabase, and test files before editing.
- Keeps OpenAI calls out of the Swift client.
- Runs or proposes the Xcode build command.

Pass criteria:
- No product redefinition.
- No secrets introduced.
- No direct OpenAI client call from iOS.
- Public contract changes are documented.

## Recommendation Scoring Fixtures
Create fixtures for these scenarios:
- Preference match beats generic item.
- Correct size in stock beats same style out of stock.
- Blocked color excludes an item.
- Event formality changes ranking.
- Price range penalty works.
- Stale stock reduces score but does not fully hide an item.

Pass criteria:
- Scores are deterministic.
- Reason codes match score changes.
- User-facing explanations do not claim guaranteed stock.

## AI JSON Schema Eval
Test `parse-event-context` and `generate-outfit-explanation`.

Pass criteria:
- Output validates against the documented JSON shape.
- Required keys are present.
- Unknown details appear in `missing_context`.
- No extra keys are accepted in strict mode.
- Refusals or failures return a recoverable app state.

## Scraper Dry-Run Eval
Each scraper source needs saved fixtures.

Pass criteria:
- Approved selectors parse expected size and stock values.
- Missing selectors return warnings.
- Rate limit config exists.
- Compliance status is not omitted.
- `manual_only` sources do not live fetch.

## UI Regression Eval
Use screenshots or simulator checks for:
- Auth/welcome.
- Preference onboarding.
- Browse grid.
- Product detail availability.
- Event creation.
- Event recommendation result.

Pass criteria:
- No overlapping controls.
- Text fits.
- Main images load.
- Back/close/search/add gestures still work.
- Stock warnings and AI explanations fit mobile surfaces.

