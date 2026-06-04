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
    error_code: "not_implemented",
    msg: "Debug scoring is defined in Swift fixtures for now; port the deterministic scorer here before deployment.",
    contract: {
      input: {
        preferences: "object",
        garments: ["object"],
        stock_snapshots: ["object"],
        event_context: "object",
        feedback: ["object"],
      },
      output: {
        ranked_items: ["{ garment_id, score, score_breakdown, reason_codes, stock_warnings }"],
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
