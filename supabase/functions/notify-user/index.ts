// Supabase Edge Function: notify-user
// Deploy at: supabase/functions/notify-user/index.ts
//
// This function is called by the iOS app whenever a push notification should
// be sent to another user. It looks up that user's registered APNs device
// tokens from the `device_tokens` table and delivers the notification via
// Apple's HTTP/2 APNs API using JWT authentication.
//
// ─────────────────────────────────────────────────────────────────────────────
// SETUP STEPS (run once in Supabase Dashboard → Settings → Edge Functions):
// ─────────────────────────────────────────────────────────────────────────────
// 1. Add the following secrets to your Supabase project:
//    APNS_TEAM_ID       → Your Apple Developer Team ID (10-char string)
//    APNS_KEY_ID        → The Key ID of your .p8 push key
//    APNS_PRIVATE_KEY   → The full contents of the .p8 file (including header/footer)
//    APNS_BUNDLE_ID     → Your app's bundle ID, e.g. com.yourname.uniride
//    APNS_ENDPOINT      → https://api.push.apple.com  (production)
//                      OR https://api.sandbox.push.apple.com  (development/TestFlight)
//
// 2. Create the `device_tokens` table (SQL — run once in Supabase SQL Editor):
//
//    create table public.device_tokens (
//      id           uuid primary key default gen_random_uuid(),
//      user_id      uuid not null references public.profiles(id) on delete cascade,
//      token        text not null,
//      platform     text not null default 'ios',
//      updated_at   timestamptz not null default now(),
//      unique (user_id, token)
//    );
//    -- Allow users to manage only their own tokens
//    alter table public.device_tokens enable row level security;
//    create policy "user owns tokens"
//      on public.device_tokens for all
//      using (auth.uid() = user_id)
//      with check (auth.uid() = user_id);
//
// 3. Deploy this function:
//    supabase functions deploy notify-user
// ─────────────────────────────────────────────────────────────────────────────

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.9/mod.ts";

const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY")!;
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID")!;
const APNS_ENDPOINT = Deno.env.get("APNS_ENDPOINT") ?? "https://api.sandbox.push.apple.com";

// ── JWT helpers ──────────────────────────────────────────────────────────────

async function importApnsKey(pem: string): Promise<CryptoKey> {
    // Strip PEM header/footer and whitespace
    const b64 = pem
        .replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----/g, "")
        .replace(/\s+/g, "");
    const der = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
    return crypto.subtle.importKey(
        "pkcs8",
        der,
        { name: "ECDSA", namedCurve: "P-256" },
        false,
        ["sign"]
    );
}

async function makeApnsJwt(): Promise<string> {
    const key = await importApnsKey(APNS_PRIVATE_KEY);
    return create(
        { alg: "ES256", kid: APNS_KEY_ID },
        { iss: APNS_TEAM_ID, iat: getNumericDate(0) },
        key
    );
}

// ── APNs send ────────────────────────────────────────────────────────────────

async function sendApns(opts: {
    deviceToken: string;
    title: string;
    body: string;
    data?: Record<string, string>;
    jwt: string;
}) {
    const url = `${APNS_ENDPOINT}/3/device/${opts.deviceToken}`;
    const payload = {
        aps: {
            alert: { title: opts.title, body: opts.body },
            badge: 1,
            sound: "default",
        },
        ...opts.data,
    };

    const res = await fetch(url, {
        method: "POST",
        headers: {
            authorization: `bearer ${opts.jwt}`,
            "apns-topic": APNS_BUNDLE_ID,
            "apns-push-type": "alert",
            "apns-priority": "10",
            "content-type": "application/json",
        },
        body: JSON.stringify(payload),
    });

    if (!res.ok) {
        const err = await res.text();
        console.error(`APNs error for token ${opts.deviceToken.slice(0, 8)}…: ${err}`);
    }
}

// ── Edge Function handler ────────────────────────────────────────────────────

serve(async (req) => {
    try {
        const authHeader = req.headers.get("authorization");
        if (!authHeader) {
            return new Response("Unauthorized", { status: 401 });
        }

        const supabase = createClient(
            Deno.env.get("SUPABASE_URL")!,
            Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
        );

        const { recipient_user_id, title, body, data } = await req.json() as {
            recipient_user_id: string;
            title: string;
            body: string;
            data?: Record<string, string>;
        };

        if (!recipient_user_id || !title || !body) {
            return new Response("Bad Request", { status: 400 });
        }

        // Fetch all device tokens for this user
        const { data: tokens, error } = await supabase
            .from("device_tokens")
            .select("token")
            .eq("user_id", recipient_user_id)
            .eq("platform", "ios");

        if (error) throw error;
        if (!tokens || tokens.length === 0) {
            return new Response(JSON.stringify({ sent: 0, reason: "no_tokens" }), {
                headers: { "content-type": "application/json" },
            });
        }

        // Generate one JWT (valid for 60 min; reuse for all tokens in this request)
        const jwt = await makeApnsJwt();

        // Send in parallel
        await Promise.all(
            tokens.map((t: { token: string }) =>
                sendApns({ deviceToken: t.token, title, body, data, jwt })
            )
        );

        return new Response(JSON.stringify({ sent: tokens.length }), {
            headers: { "content-type": "application/json" },
        });
    } catch (err) {
        console.error("notify-user error:", err);
        return new Response("Internal Server Error", { status: 500 });
    }
});
