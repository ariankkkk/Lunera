# Event Outfit Spec

## Goal
Help users prepare for an event by turning a description into a practical, stylish outfit recommendation that respects preferences and store availability.

## Event Creation Fields
- Title
- Date
- Optional location
- Optional image
- Description or prompt
- Optional dress code
- Optional mood tags

Current prototype fields are a valid visual baseline. Future implementation should persist the event and recommendation result.

## Event Context
The app should infer:
- Event type: dinner, wedding, holiday, work, party, date, travel, casual, formal, other.
- Dress code: casual, smart casual, business, cocktail, formal, unknown.
- Formality: 0 to 1.
- Mood tags: elegant, cozy, bold, minimal, festive, romantic, classic.
- Season/weather placeholders.
- Color hints.
- Avoid tags.
- Missing context.

AI can parse the description, but deterministic defaults must handle empty or ambiguous descriptions.

## Recommendation Behavior
For each event recommendation:
- Fetch user preferences.
- Fetch candidate garments and fresh stock.
- Extract event context.
- Score items and assemble outfit candidates.
- Generate a concise explanation.
- Save recommendation and score metadata.

The recommendation should show:
- Main outfit items.
- Why each item was chosen.
- Store and size availability.
- Stock freshness warning when needed.
- Confidence indicator or subtle uncertainty state.

## UI States
- Draft: event form is incomplete.
- Parsing: event context is being extracted.
- Scoring: recommendation is being ranked.
- Ready: recommendation is available.
- Partial: recommendation is available but has stock or context warnings.
- Failed: retry and manual browse fallback are available.

## Feedback
Users can:
- Like an outfit.
- Dislike an outfit.
- Hide an item.
- Mark an item as unavailable or wrong.
- Save an outfit for the event.

Feedback updates future scoring. It should not silently rewrite the saved event description.

## Acceptance Criteria
- Empty descriptions still produce a safe generic recommendation.
- Ambiguous events ask for or display missing context instead of inventing details.
- Formality changes item ranking.
- Unavailable sizes are penalized.
- Recommendations never claim guaranteed in-store stock.

