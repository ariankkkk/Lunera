# Lunera Design System

## Direction
Lunera should feel premium, native, visual, and calm. The current SwiftUI prototype is the baseline. Changes should improve clarity and usability without turning the app into a marketing page or generic dashboard.

## Visual Principles
- Fashion imagery leads the experience.
- UI chrome should be quiet and tactile.
- Use native SwiftUI and iOS Liquid Glass for tappable pill and circular controls when available.
- Keep custom flat fills only as availability fallbacks.
- Preserve the light visual mood unless a feature explicitly requires contrast.

## Layout
- Optimize first for iPhone.
- Use stable dimensions for repeated cards, controls, grids, and tab bars.
- Avoid nested cards.
- Avoid explanatory text that describes how to use obvious controls.
- Keep hit targets comfortable and predictable.
- Text must fit inside controls on small devices.

## Components
- Buttons: use icons for common actions such as back, add, edit, search, close, and favorite.
- Cards: use for repeated garment, event, or recommendation items only.
- Segmented controls: use for tabs inside a detail flow, such as details/care/availability.
- Forms: keep event and preference input minimal, focused, and keyboard-safe.
- Empty states: provide a direct action, not a long explanation.

## Colors And Type
- Use the existing soft neutral background and dark ink tone as the baseline.
- Avoid a one-note palette dominated by one hue.
- Use typography hierarchy appropriate to the surface: large only for first-screen brand moments, compact inside details and cards.
- Letter spacing should remain normal unless matching an existing brand treatment.

## Recommendation UI
- Show recommendations as outfits, not isolated algorithm output.
- Every recommendation should have a clear reason that maps to a reason code.
- Stock warnings should be visible but not alarming.
- Do not show raw AI text if it violates tone, length, or certainty rules.

## Screenshot Verification
For visual changes, capture or review:
- Welcome/auth flow.
- Home browse grid.
- Product detail.
- Event list.
- Event creation.
- Event recommendation result.

Check that controls do not overlap, text fits, images load, and gestures still work.

