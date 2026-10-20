// =============================================================================
// ai-tutor: Supabase Edge Function (Deno)
//
// Flow:
//   1. Verify the caller's JWT (Supabase verifies it by default).
//   2. Validate and bound the request (size, role order, NQF level).
//   3. Consume one query atomically with consume_ai_query() under the learner's
//      own JWT. The database enforces the daily limit, not the client.
//   4. Call the LLM (Gemini here) with a server-only API key.
//   5. On an upstream failure, refund the query and return 502.
//
// Deploy:  supabase functions deploy ai-tutor
// Secrets: supabase secrets set GEMINI_API_KEY=... [AI_MODEL=gemini-2.5-flash]
// =============================================================================

import { createClient } from 'npm:@supabase/supabase-js@2';

type Role = 'user' | 'assistant';
interface ChatTurn {
  role: Role;
  content: string;
}
interface RequestBody {
  messages: ChatTurn[];
  nqf_level: number;
  vocational_stream: string;
}

const MAX_TURNS = 12;
const MAX_CHARS_PER_TURN = 2000;
const MAX_STREAM_CHARS = 120;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function validate(body: unknown): { ok: true; value: RequestBody } | { ok: false; error: string } {
  if (typeof body !== 'object' || body === null) return { ok: false, error: 'invalid_body' };
  const b = body as Record<string, unknown>;

  const messages = b.messages;
  if (!Array.isArray(messages) || messages.length === 0 || messages.length > MAX_TURNS) {
    return { ok: false, error: 'invalid_messages' };
  }
  for (const m of messages) {
    if (typeof m !== 'object' || m === null) return { ok: false, error: 'invalid_message' };
    const turn = m as Record<string, unknown>;
    if (turn.role !== 'user' && turn.role !== 'assistant') return { ok: false, error: 'invalid_role' };
    if (typeof turn.content !== 'string' || turn.content.trim().length === 0) {
      return { ok: false, error: 'empty_message' };
    }
    if (turn.content.length > MAX_CHARS_PER_TURN) return { ok: false, error: 'message_too_long' };
  }
  const last = messages[messages.length - 1] as ChatTurn;
  if (last.role !== 'user') return { ok: false, error: 'last_message_must_be_user' };

  const nqf = Number(b.nqf_level);
  if (![2, 3, 4].includes(nqf)) return { ok: false, error: 'invalid_nqf_level' };

  const stream = typeof b.vocational_stream === 'string' ? b.vocational_stream.slice(0, MAX_STREAM_CHARS) : '';

  return {
    ok: true,
    value: { messages: messages as ChatTurn[], nqf_level: nqf, vocational_stream: stream },
  };
}

function systemPrompt(nqf: number, stream: string): string {
  const streamText = stream ? `, stream: ${stream}` : '';
  return [
    `You are NCV Companion's study tutor for South African NCV Level ${nqf} students${streamText}.`,
    'Explain clearly and simply, at TVET learner level, using South African examples where helpful (for example, rands and local workplaces).',
    'For Mathematics and calculations, show short, numbered working steps.',
    'Guide learners toward answers. Do not write full answers to graded assessments; give hints and worked examples on similar problems instead.',
    'If a question is unrelated to school or study, politely redirect to the learner\'s subjects.',
    'Keep answers concise. Use plain text with simple bullet points.',
  ].join(' ');
}

async function callGemini(system: string, messages: ChatTurn[]): Promise<string> {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  if (!apiKey) throw new Error('GEMINI_API_KEY is not configured');
  const model = Deno.env.get('AI_MODEL') ?? 'gemini-2.5-flash';

  // Gemini expects the conversation to start with a user turn.
  const start = messages.findIndex((m) => m.role === 'user');
  const trimmed = start > 0 ? messages.slice(start) : messages;

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: trimmed.map((m) => ({
          role: m.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: m.content }],
        })),
        generationConfig: { temperature: 0.4, maxOutputTokens: 1024 },
      }),
    },
  );

  if (!res.ok) {
    throw new Error(`Gemini responded ${res.status}: ${(await res.text()).slice(0, 300)}`);
  }

  const data = await res.json();
  const text: string = (data?.candidates?.[0]?.content?.parts ?? [])
    .map((p: { text?: string }) => p.text ?? '')
    .join('')
    .trim();

  if (!text) throw new Error('Empty reply from model');
  return text;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'unauthorized' }, 401);

  let parsed: unknown;
  try {
    parsed = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const check = validate(parsed);
  if (!check.ok) return json({ error: check.error }, 400);

  // Use the learner's JWT so auth.uid() inside the SQL functions is the learner.
  // The service-role key is not needed here.
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );

  const { data: quota, error: quotaError } = await supabase.rpc('consume_ai_query');
  if (quotaError) {
    const unauthenticated = quotaError.message?.includes('not authenticated');
    return json({ error: unauthenticated ? 'unauthorized' : 'quota_check_failed' }, unauthenticated ? 401 : 500);
  }

  const row = Array.isArray(quota) ? quota[0] : quota;
  if (!row?.allowed) {
    return json({ error: 'quota_exceeded', remaining: 0 }, 429);
  }

  try {
    const reply = await callGemini(systemPrompt(check.value.nqf_level, check.value.vocational_stream), check.value.messages);
    return json({ reply, remaining: Number(row.remaining) });
  } catch (error) {
    console.error('ai-tutor upstream failure', error);
    await supabase.rpc('refund_ai_query');
    return json({ error: 'upstream_error' }, 502);
  }
});
