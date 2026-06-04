# Lunera

Lunera is a SwiftUI iOS fashion app for personalized clothing discovery, Baku store stock awareness, and event-based outfit recommendations.

## Project Structure

- `Lunera/App`: app entry point and root navigation.
- `Lunera/Core`: shared design system and reusable core code.
- `Lunera/Features`: feature-specific SwiftUI screens and flows.
- `Lunera/Resources`: asset catalogs and preview resources.
- `Lunera/Supporting`: app configuration files such as `Info.plist`.
- `Assets`: brand and reference source assets that are not compiled directly into the app.
- `Artifacts`: local screenshots and generated verification output.
- `Docs`: product, UI, and engineering notes.

## AI Factory Docs

Start with `AGENTS.md` and these docs before implementing product changes:

- `Docs/PRODUCT_SPEC.md`
- `Docs/ARCHITECTURE.md`
- `Docs/DATA_MODEL.md`
- `Docs/AI_RECOMMENDATION_SPEC.md`
- `Docs/INVENTORY_SCRAPING_SPEC.md`
- `Docs/EVENT_OUTFIT_SPEC.md`
- `Docs/DESIGN_SYSTEM.md`
- `Docs/ROADMAP.md`
- `Docs/TASK_TEMPLATE.md`
- `Docs/EVALS.md`

## Development

Open `Lunera.xcodeproj` in Xcode and run the `Lunera` scheme.

Smoke build:

```sh
xcodebuild -project Lunera.xcodeproj -scheme Lunera -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```
