# AI Recommendation Spec

## Goal
Lunera recommends outfits by combining user preferences, garment metadata, store availability, event context, and outfit compatibility. Ranking must be deterministic and testable. AI is used to understand language and explain recommendations, not to secretly choose the final result.

## Inputs
- User preferences: sizes, colors, brands, price range, locations, style tags, dislikes.
- Garments: category, color, brand, size, price, season tags, style tags, image metadata.
- Stock snapshots: store, size, stock state, observed time, confidence.
- Event context: event type, date, location, dress code, mood, weather placeholder, description.
- Feedback: likes, dislikes, hidden items, selected recommendations.

## Event Context Extraction
`parse-event-context` receives user event fields and returns structured JSON.

Required output:
```json
{
  "event_context": {
    "event_type": "dinner",
    "dress_code": "smart_casual",
    "formality": 0.7,
    "mood_tags": ["elegant", "warm"],
    "season_hint": "winter",
    "location_hint": "Baku",
    "color_hints": ["black", "cream"],
    "avoid_tags": [],
    "missing_context": ["weather"]
  }
}
```

Rules:
- Return only schema-valid JSON.
- Use `missing_context` when details are not present.
- Do not invent exact weather or store availability.

## Deterministic Scoring
Each candidate item receives a normalized score from 0 to 100.

Default weights:
- Size match: 25
- Stock availability and freshness: 20
- Style preference match: 20
- Event context match: 15
- Color and brand preference match: 10
- Price range fit: 5
- Feedback history: 5

Penalties:
- Blocked color or brand: exclude unless user explicitly overrides.
- Unavailable preferred size: strong penalty.
- Stale stock snapshot: reduce stock score.
- Event mismatch, such as casual item for formal event: reduce event score.

Outfit-level score considers:
- Category coverage, such as top, bottom, outerwear, shoes, accessory where relevant.
- Color harmony.
- Formality consistency.
- Seasonal appropriateness.
- User preference consistency.

## AI Explanation
`generate-outfit-explanation` receives ranked items, score breakdown, stock warnings, and event context. It returns display-safe JSON.

Required output:
```json
{
  "recommended_items": [
    {
      "garment_id": "uuid",
      "role": "top",
      "reason_codes": ["style_match", "in_stock_nearby"],
      "display_reason": "Matches your cream color preference and is recently available in your size."
    }
  ],
  "reason_codes": ["event_match", "stock_available", "preference_match"],
  "confidence": 0.82,
  "stock_warnings": ["Stock was last checked 3 hours ago."],
  "user_facing_explanation": "This outfit leans elegant but comfortable for your event, with pieces that match your preferred colors and recent Baku store availability."
}
```

Rules:
- Do not mention private scoring internals unless this is a debug endpoint.
- Do not claim guaranteed availability.
- Do not recommend blocked items unless the response labels it as an explicit fallback.
- Keep explanations short enough for mobile UI.

## Feedback Loop
Feedback changes deterministic scoring:
- Like: boost similar style tags, colors, categories, and brands.
- Dislike: reduce similar items and store reasons.
- Hide item: exclude the exact garment for that user.
- Chosen recommendation: boost its outfit template.

## Evaluation Fixtures
Create fixtures for:
- Preference match beats generic item.
- In-stock correct size beats out-of-stock correct style.
- Event dress code changes category and formality ranking.
- Blocked brand is excluded.
- Price range filters expensive items.
- Explanation JSON validates against schema.

