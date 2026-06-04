import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";

const usernameEmailDomain = "users.lunera.app";
const usernamePattern = /^[a-z0-9._]{3,24}$/;

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
    return errorResponse(405, "method_not_allowed", "Use POST.");
  }

  if (!isAuthorizedAppRequest(req)) {
    return errorResponse(401, "unauthorized", "Missing Lunera API key.");
  }

  let payload: SignupPayload;
  try {
    payload = await req.json();
  } catch {
    return errorResponse(400, "invalid_json", "Request body must be JSON.");
  }

  const username = normalizeUsername(payload.username);
  const password = typeof payload.password === "string" ? payload.password : "";

  if (!usernamePattern.test(username)) {
    return errorResponse(400, "invalid_username", "Use 3-24 letters, numbers, dots, or underscores.");
  }

  if (password.length < 6) {
    return errorResponse(400, "invalid_password", "Password must be at least 6 characters.");
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse(500, "server_not_configured", "Username signup is not configured.");
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const email = authEmail(username);
  const userMetadata = {
    username,
    display_name: username,
    auth_source: "lunera_username",
  };

  const existingUser = await findUserByEmail(admin, email);
  if (existingUser) {
    const confirmed = Boolean(existingUser.email_confirmed_at || existingUser.confirmed_at);
    if (confirmed) {
      return errorResponse(409, "account_exists", "That username already exists.");
    }

    const { error } = await admin.auth.admin.updateUserById(existingUser.id, {
      password,
      email_confirm: true,
      user_metadata: userMetadata,
    });

    if (error) {
      return errorResponse(500, "user_update_failed", "Could not finish username signup.");
    }

    return signInAndRespond(admin, email, password);
  }

  const { error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: userMetadata,
  });

  if (createError) {
    const normalizedMessage = createError.message.toLowerCase();
    if (normalizedMessage.includes("already") || normalizedMessage.includes("registered")) {
      return errorResponse(409, "account_exists", "That username already exists.");
    }

    if (normalizedMessage.includes("password")) {
      return errorResponse(400, "invalid_password", createError.message);
    }

    return errorResponse(500, "user_create_failed", "Could not create username account.");
  }

  return signInAndRespond(admin, email, password);
});

type SignupPayload = {
  username?: unknown;
  password?: unknown;
};

type SupabaseAdminClient = ReturnType<typeof createClient>;

type SupabaseAuthUser = {
  id: string;
  email?: string;
  confirmed_at?: string | null;
  email_confirmed_at?: string | null;
};

function normalizeUsername(value: unknown): string {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function authEmail(username: string): string {
  const safeLocalPart = username.replaceAll(".", "-dot-").replaceAll("_", "-under-");
  return `${safeLocalPart}@${usernameEmailDomain}`;
}

async function findUserByEmail(admin: SupabaseAdminClient, email: string): Promise<SupabaseAuthUser | null> {
  for (let page = 1; page <= 5; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });

    if (error) {
      throw error;
    }

    const match = data.users.find((user) => user.email?.toLowerCase() === email);
    if (match) {
      return match;
    }

    if (data.users.length < 1000) {
      return null;
    }
  }

  return null;
}

async function signInAndRespond(admin: SupabaseAdminClient, email: string, password: string): Promise<Response> {
  const { data, error } = await admin.auth.signInWithPassword({ email, password });

  if (error || !data.session) {
    return errorResponse(500, "session_create_failed", "Account was created, but sign in failed.");
  }

  return jsonResponse(200, {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_in: data.session.expires_in,
    expires_at: data.session.expires_at,
    user: data.user,
  });
}

function isAuthorizedAppRequest(req: Request): boolean {
  const allowedKeys = configuredPublishableKeys();
  const apiKey = req.headers.get("apikey");
  const bearer = bearerToken(req.headers.get("authorization"));

  return allowedKeys.some((key) => key === apiKey || key === bearer);
}

function configuredPublishableKeys(): string[] {
  const keys = new Set<string>();
  const legacyAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (legacyAnonKey) {
    keys.add(legacyAnonKey);
  }

  const publishableKeys = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (publishableKeys) {
    try {
      const parsed = JSON.parse(publishableKeys) as Record<string, unknown>;
      for (const value of Object.values(parsed)) {
        if (typeof value === "string") {
          keys.add(value);
        }
      }
    } catch {
      // Ignore malformed platform config and rely on legacy anon key if present.
    }
  }

  return Array.from(keys);
}

function bearerToken(header: string | null): string | null {
  if (!header) {
    return null;
  }

  const [scheme, token] = header.split(" ");
  return scheme?.toLowerCase() === "bearer" && token ? token : null;
}

function errorResponse(status: number, code: string, message: string): Response {
  return jsonResponse(status, {
    error_code: code,
    msg: message,
  });
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Connection": "keep-alive",
    },
  });
}
