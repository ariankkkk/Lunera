import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error_code: "method_not_allowed", msg: "Use POST." });
  }

  return jsonResponse(501, {
    error_code: "source_not_approved",
    msg: "Store ingestion requires a documented robots/ToS check, source adapter, and dry-run fixture before live scraping.",
    contract: {
      input: {
        source_id: "string",
        dry_run: "boolean",
      },
      output: {
        source_id: "string",
        snapshots_inserted: "number",
        stale_snapshot_ids: ["uuid"],
        warnings: ["string"],
      },
    },
  });
});

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
