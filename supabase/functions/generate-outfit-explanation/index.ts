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

  if (!Deno.env.get("OPENAI_API_KEY")) {
    return jsonResponse(501, {
      error_code: "openai_not_configured",
      msg: "Set OPENAI_API_KEY before enabling outfit explanations.",
      contract: {
        input: {
          event_context: "object",
          ranked_items: ["object"],
          score_breakdown: "object",
          stock_warnings: ["string"],
        },
        output: {
          recommended_items: ["{ garment_id, role, reason_codes, display_reason }"],
          reason_codes: ["string"],
          confidence: "number",
          stock_warnings: ["string"],
          user_facing_explanation: "string",
        },
      },
    });
  }

  return jsonResponse(501, {
    error_code: "not_implemented",
    msg: "Structured OpenAI explanation generation will be implemented after secret setup.",
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
