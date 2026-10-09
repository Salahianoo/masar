import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {describe, expect, it, vi} from "vitest";
import {assembleMentorPrompt, formatGroundingQuestion, MENTOR_PROMPT_TEMPLATE} from "./mentor-prompt";
import {BUSY_REPLY, PcUnavailableError, requestPcReply, resolveMentorReply,
  stripThinkBlocks} from "./mentor-transport";

describe("رفيق prompt", () => {
  it("copies the exact marked persona and fills every placeholder", () => {
    const doc = readFileSync(resolve(process.cwd(), "../docs/mentor-persona.md"), "utf8");
    const marked = doc.split("<!-- PROMPT:START -->")[1].split("<!-- PROMPT:END -->")[0].trim();
    expect(MENTOR_PROMPT_TEMPLATE).toBe(marked);
    const system = assembleMentorPrompt({mentorName: "رفيق", subjectName: "ثقافة صحية",
      studentState: "ضعيف (25%)", grounding: "س: سؤال / الجواب الصحيح: أ"});
    expect(system).toContain("إنت رفيق، رفيق دراسة");
    expect(system).toContain("ثقافة صحية");
    expect(system).toContain("ضعيف (25%)");
    expect(system).toContain("س: سؤال / الجواب الصحيح: أ");
    expect(system).not.toMatch(/\{(?:mentorName|subjectName|studentState|grounding)\}/);
  });

  it("marks the correct option's label and text in each exam question", () => {
    expect(formatGroundingQuestion({text: "أول إجراء؟", options: [
      {label: "أ", text: "رفع الطرف"}, {label: "ب", text: "الضغط المباشر"},
    ], answer: "ب"})).toBe("س: أول إجراء؟ [أ) رفع الطرف | ب) الضغط المباشر] / الجواب الصحيح: ب) الضغط المباشر");
  });
});

describe("PC mentor transport", () => {
  const options = {baseUrl: "https://rafeeq.example.test", token: "masar-token",
    system: "prompt", messages: [{role: "user" as const, text: "اشرح النزيف"}]};

  it("sends the exact Qwen settings through Masar's endpoint and strips think blocks", async () => {
    const fetchImpl = vi.fn(async (_url: RequestInfo | URL, init?: RequestInit) => {
      expect(init?.headers).toMatchObject({Authorization: "Bearer masar-token"});
      expect(JSON.parse(String(init?.body))).toMatchObject({model: "qwen/qwen3.5-9b",
        reasoning_effort: "none", temperature: 0.4, max_tokens: 500, stream: true});
      return new Response("data: {\"choices\":[{\"delta\":{\"content\":\"<think>hidden</think>الجواب\"}}]}\n\ndata: [DONE]\n", {
        status: 200, headers: {"content-type": "text/event-stream"},
      });
    });
    expect(await requestPcReply({...options, fetchImpl: fetchImpl as typeof fetch})).toBe("الجواب");
    expect(fetchImpl.mock.calls[0][0]).toBe("https://rafeeq.example.test/v1/chat/completions");
    expect(stripThinkBlocks("قبل <think>سر</think> بعد")).toBe("قبل بعد");
  });

  it("treats HTTP 503 as busy, falling back only when configured", async () => {
    const pc = () => requestPcReply({...options,
      fetchImpl: vi.fn(async () => new Response('{"error":{"message":"busy"}}', {status: 503})) as typeof fetch});
    const cloud = vi.fn(async () => "جواب من السحابة");
    await expect(pc()).rejects.toBeInstanceOf(PcUnavailableError);
    expect(await resolveMentorReply({source: "pc", fallbackToCloud: false, pc, cloud}))
      .toEqual({reply: BUSY_REPLY, source: null});
    expect(cloud).not.toHaveBeenCalled();
    expect(await resolveMentorReply({source: "pc", fallbackToCloud: true, pc, cloud}))
      .toEqual({reply: "جواب من السحابة", source: "cloud"});
    expect(cloud).toHaveBeenCalledOnce();
  });

  it("treats a missing first token as PC unavailable", async () => {
    const fetchImpl = (_url: RequestInfo | URL, init?: RequestInit) => new Promise<Response>((_resolve, reject) => {
      init?.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")));
    });
    await expect(requestPcReply({...options, fetchImpl: fetchImpl as typeof fetch,
      firstTokenTimeoutMs: 5})).rejects.toBeInstanceOf(PcUnavailableError);
  });
});
