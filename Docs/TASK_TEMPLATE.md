# Lunera Agent Task Template

Use this template when asking Codex or another agent to build a Lunera feature.

## Task
One sentence describing the desired change.

## Product Context
- Relevant product spec sections:
- Relevant architecture/data docs:
- User flow affected:

## Goal
What should be true after the task is complete?

## In Scope
- Specific files, features, data models, or screens to change.

## Out Of Scope
- Explicitly list anything the agent must not change.

## Implementation Constraints
- Preserve current visual baseline unless requested.
- Keep OpenAI calls server-side.
- Use structured JSON for AI outputs.
- Do not run Supabase migrations or deploy functions unless requested.
- Do not commit secrets.

## Expected Files
- Swift files:
- Supabase migrations or functions:
- Docs to update:
- Tests or fixtures:

## Verification
For Swift changes, run:

```sh
xcodebuild -project Lunera.xcodeproj -scheme Lunera -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

For docs-only changes:
- Check all referenced files exist.
- Check new docs match `AGENTS.md`.
- Check terms are consistent across product, data, AI, and architecture docs.

For Supabase changes:
- List tables before migration.
- Apply migration only when requested.
- Run security and performance advisors afterward.

## Done Criteria
- The goal is implemented.
- Acceptance criteria are met.
- Build/tests/checks were run or clearly noted as not run.
- Any changed public contract is documented.

## Example Task
Build Phase 3 preference capture. Use `Docs/PRODUCT_SPEC.md`, `Docs/DATA_MODEL.md`, and `Docs/AI_RECOMMENDATION_SPEC.md`. Add real preference inputs, persist them through Supabase repositories, and keep the current onboarding visual style.

