export type MentorSource = "pc" | "cloud";
export type MentorMessage = {role: "user" | "mentor"; text: string};
export const BUSY_REPLY = "رفيق مشغول هلق، جرب كمان شوي";

export class PcUnavailableError extends Error {}

export function stripThinkBlocks(value: string): string {
  return value.replace(/<think>[\s\S]*?(?:<\/think>\s*|$)/gi, "").trim();
}

export async function requestPcReply(options: {
  baseUrl: string;
  token: string;
  system: string;
  messages: MentorMessage[];
  fetchImpl?: typeof fetch;
  firstTokenTimeoutMs?: number;
  completionTimeoutMs?: number;
}): Promise<string> {
  const controller = new AbortController();
  let firstToken = false;
  const firstTimer = setTimeout(() => controller.abort(), options.firstTokenTimeoutMs ?? 12000);
  const completionTimer = setTimeout(() => controller.abort(), options.completionTimeoutMs ?? 60000);
  try {
    const url = `${options.baseUrl.replace(/\/+$/, "")}/v1/chat/completions`;
    const response = await (options.fetchImpl ?? fetch)(url, {
      method: "POST", signal: controller.signal,
      headers: {"Content-Type": "application/json", "Authorization": `Bearer ${options.token}`},
      body: JSON.stringify({
        model: "qwen/qwen3.5-9b", stream: true, reasoning_effort: "none",
        temperature: 0.4, max_tokens: 500,
        messages: [{role: "system", content: options.system}, ...options.messages.map((message) => ({
          role: message.role === "mentor" ? "assistant" : "user", content: message.text,
        }))],
      }),
    });
    if (response.status === 503) throw new PcUnavailableError("PC busy");
    if (!response.ok || !response.body) throw new Error(`PC model HTTP ${response.status}`);
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let raw = "";
    let reading = true;
    while (reading) {
      const {value, done} = await reader.read();
      buffer += decoder.decode(value, {stream: !done});
      const lines = buffer.split("\n");
      buffer = done ? "" : lines.pop() ?? "";
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith("data: ") || trimmed === "data: [DONE]") continue;
        const parsed = JSON.parse(trimmed.slice(6));
        const content = parsed.choices?.[0]?.delta?.content;
        if (typeof content === "string" && content) {
          if (!firstToken) {
            firstToken = true;
            clearTimeout(firstTimer);
          }
          raw += content;
        }
      }
      if (done) reading = false;
    }
    const reply = stripThinkBlocks(raw);
    if (!reply) throw new Error("Empty PC reply");
    return reply;
  } catch (error) {
    if (!firstToken && controller.signal.aborted) throw new PcUnavailableError("PC first-token timeout");
    throw error;
  } finally {
    clearTimeout(firstTimer);
    clearTimeout(completionTimer);
  }
}

export async function requestCloudReply(options: {
  token: string;
  model: string;
  system: string;
  messages: MentorMessage[];
  fetchImpl?: typeof fetch;
}): Promise<string> {
  const response = await (options.fetchImpl ?? fetch)("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {"Content-Type": "application/json", "x-api-key": options.token,
      "anthropic-version": "2023-06-01"},
    body: JSON.stringify({model: options.model, max_tokens: 500, system: options.system,
      messages: options.messages.map((message) => ({
        role: message.role === "mentor" ? "assistant" : "user", content: message.text,
      }))}),
  });
  if (!response.ok) throw new Error(`Cloud model HTTP ${response.status}`);
  const body = await response.json() as {content?: {type: string; text?: string}[]};
  const reply = body.content?.filter((item) => item.type === "text")
    .map((item) => item.text ?? "").join(" ").trim();
  if (!reply) throw new Error("Empty cloud reply");
  return reply;
}

export async function resolveMentorReply(options: {
  source: MentorSource;
  fallbackToCloud: boolean;
  pc: () => Promise<string>;
  cloud: () => Promise<string>;
}): Promise<{reply: string; source: MentorSource | null}> {
  if (options.source === "cloud") return {reply: await options.cloud(), source: "cloud"};
  try {
    return {reply: await options.pc(), source: "pc"};
  } catch (error) {
    if (!(error instanceof PcUnavailableError)) throw error;
    if (!options.fallbackToCloud) return {reply: BUSY_REPLY, source: null};
    return {reply: await options.cloud(), source: "cloud"};
  }
}
