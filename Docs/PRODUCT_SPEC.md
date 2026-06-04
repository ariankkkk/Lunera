# Lunera Product Spec

## Product
Lunera is a native iOS fashion assistant that helps users discover clothing, understand local store stock, and prepare outfits for real events. It should feel like a premium fashion app: visual, calm, personal, and practical.

## Target User
- Fashion-conscious iPhone users in Baku who want curated clothing suggestions without manually checking many stores.
- Users who care about fit, budget, color, brand, location, and occasion.
- Users preparing for events who want an outfit recommendation that feels personal and available nearby.

## Core Flows

### Onboarding And Preferences
Users create an account or sign in, then provide style preferences:
- Sizes
- Color preferences
- Brand preferences
- Price range
- Location or preferred stores
- Style mood, such as minimal, elegant, classic, bold, casual, formal
- Optional dislikes, such as colors, fits, brands, or item categories to avoid

Success means the app can store preferences and explain why later recommendations match them.

### Browse And Closet
Users browse clothing cards and open detailed product views. Product details should include:
- Images
- Brand
- Category
- Color
- Sizes
- Price range
- Care/details
- Store availability
- Recommendation reasons when applicable

The current SwiftUI prototype is the visual baseline for this flow.

### Store Stock
The app tracks Baku store availability through documented inventory sources. V1 uses scraper-backed stock snapshots with manual fallback. Stock is displayed as recent availability, not a guaranteed reservation.

Success means a user can see whether a relevant size is likely available at a nearby store and when the stock data was last checked.

### Event Outfit Recommendations
Users create an event by entering a title, date, image, and description. Lunera extracts context from the description and recommends outfits based on:
- Event type
- Dress code
- Time/date
- Season/weather placeholder
- User style preferences
- Available stock
- Outfit compatibility

Success means the user receives a ranked outfit recommendation with clear reasons and stock warnings.

## Non-Goals For V1
- No checkout or payment flow.
- No guaranteed reservation of store inventory.
- No fully autonomous scraping without source review.
- No model training pipeline.
- No direct OpenAI calls from the iOS client.
- No global multi-country inventory system until the Baku flow works.

## Acceptance Criteria
- The app can represent preferences, garments, stores, stock snapshots, events, recommendations, and feedback.
- Recommendations are reproducible from deterministic scores.
- AI outputs are schema-constrained and safe to render in the app.
- Stock sources are documented before use.
- Supabase data access follows RLS rules.
- New agent tasks can be started from `Docs/TASK_TEMPLATE.md` without re-explaining the product.

