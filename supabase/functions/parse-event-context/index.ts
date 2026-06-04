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
      msg: "Set OPENAI_API_KEY before enabling event context parsing.",
      contract: {
        input: {
          title: "string",
          description: "string",
          event_date: "string | null",
          location_text: "string | null",
        },
        output: {
          event_context: {
            event_type: "string",
            dress_code: "string",
            formality: "number",
            mood_tags: ["string"],
            season_hint: "string | null",
            location_hint: "string | null",
            color_hints: ["string"],
            avoid_tags: ["string"],
            missing_context: ["string"],
          },
        },
      },
    });
  }

  return jsonResponse(501, {
    error_code: "not_implemented",
    msg: "Structured OpenAI parsing will be implemented after secret setup.",
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
