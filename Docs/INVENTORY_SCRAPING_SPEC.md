# Inventory Scraping Spec

## Goal
Track Baku store stock as recent availability signals for Lunera recommendations. Scraping must be documented, rate-limited, testable, and legally reviewed source by source.

## Source Registry
Each store source must define:
- `source_id`: stable id, such as `massimo_dutti_ganjlik`
- `brand`: store brand
- `store_name`: display name
- `city`: default `Baku`
- `target_urls`: product, search, or stock URLs
- `source_type`: `html`, `json_endpoint`, `official_api`, or `manual`
- `allowed_selectors`: CSS selectors or JSON paths approved for extraction
- `size_map`: source sizes normalized to Lunera sizes
- `stock_state_map`: source labels normalized to `in_stock`, `low_stock`, `out_of_stock`, `unknown`
- `rate_limit`: requests per minute and per day
- `compliance_status`: `pending_review`, `approved`, `blocked`, or `manual_only`
- `fallback`: manual CSV/admin update behavior

Current Baku placeholders:
- Massimo Dutti Ganjlik
- Massimo Dutti 28 May
- Massimo Dutti Crescent Mall
- Massimo Dutti Port Baku

## Compliance Rules
- Check robots.txt and public Terms of Service before live fetching.
- Prefer official APIs, feeds, or partner data over scraping.
- Do not bypass authentication, CAPTCHAs, rate limits, or anti-bot systems.
- Do not collect user data from store sites.
- Mark blocked or unclear sources as `manual_only`.

## Adapter Contract
Input:
```json
{
  "source_id": "massimo_dutti_ganjlik",
  "mode": "dry_run",
  "target_url": "https://example.com/product"
}
```

Output:
```json
{
  "source_id": "massimo_dutti_ganjlik",
  "observed_at": "2026-06-05T00:00:00Z",
  "items": [
    {
      "source_product_id": "abc123",
      "source_url": "https://example.com/product",
      "size": "S",
      "stock_state": "in_stock",
      "quantity": null,
      "confidence": 0.8,
      "raw_payload": {}
    }
  ],
  "warnings": []
}
```

## Dry-Run First
Every source must pass fixture tests before live fetching:
- Saved HTML or JSON fixture parses expected product and size states.
- Missing selectors produce warnings, not crashes.
- Unknown sizes map to `unknown`.
- Stock state normalization is deterministic.

## Stale Stock
Stock is considered:
- Fresh: observed within 6 hours.
- Aging: 6 to 24 hours.
- Stale: older than 24 hours.

UI must show stale warnings and recommendations should reduce the stock score for stale snapshots.

## Manual Fallback
Manual stock updates are allowed through CSV or admin tooling when scraping is blocked, unstable, or not yet approved. Manual updates write the same `stock_snapshots` shape with `source_type = manual`.

