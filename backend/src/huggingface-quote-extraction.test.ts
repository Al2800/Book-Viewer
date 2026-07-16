import { describe, expect, it, vi } from 'vitest';
import {
  buildHuggingFaceQuoteRequest,
  normalizeHuggingFaceQuoteResponse,
  proxyToHuggingFaceQuoteExtractor,
  resolveApprovedHuggingFaceModelId,
} from './huggingface-quote-extraction';
import type { GeminiRequest } from './types';

function makeGeminiRequest(): GeminiRequest {
  return {
    contents: [
      {
        parts: [
          { text: 'Extract only marked passages from this book page.' },
          {
            inlineData: {
              mimeType: 'image/jpeg',
              data: 'dGVzdC1pbWFnZQ==',
            },
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.1,
      maxOutputTokens: 4096,
      responseMimeType: 'application/json',
    },
  };
}

describe('buildHuggingFaceQuoteRequest', () => {
  it('builds a vision chat-completions payload from the quote extraction request', () => {
    const body = buildHuggingFaceQuoteRequest(makeGeminiRequest(), {
      modelId: 'Qwen/Qwen2.5-VL-72B-Instruct:featherless-ai',
    });

    expect(body.model).toBe('Qwen/Qwen2.5-VL-72B-Instruct:featherless-ai');
    expect(body.temperature).toBe(0.1);
    expect(body.response_format).toEqual({ type: 'json_object' });
    expect(body.messages).toHaveLength(2);
    expect(body.messages[0]?.role).toBe('system');
    expect(body.messages[1]?.content).toEqual([
      {
        type: 'text',
        text: expect.stringContaining('Extract only marked passages'),
      },
      {
        type: 'image_url',
        image_url: {
          url: 'data:image/jpeg;base64,dGVzdC1pbWFnZQ==',
        },
      },
    ]);
  });
});

describe('resolveApprovedHuggingFaceModelId', () => {
  it('accepts only an explicitly approved provider suffix', () => {
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct:featherless-ai'))
      .toBe('Qwen/Qwen2.5-VL-72B-Instruct:featherless-ai');
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct:hf-inference')).toBeNull();
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct:preferred')).toBeNull();
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct:fastest')).toBeNull();
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct')).toBeNull();
  });
});

describe('normalizeHuggingFaceQuoteResponse', () => {
  it('normalizes provider errors without forwarding an unbounded response body', async () => {
    const response = new Response(
      JSON.stringify({
        error: {
          message: 'Model is not supported by the selected provider',
          internal: 'provider-debug-data',
        },
      }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );

    const normalized = await normalizeHuggingFaceQuoteResponse(response);
    const body = await normalized.json() as { error: string; code: string };

    expect(normalized.status).toBe(400);
    expect(body).toEqual({
      error: 'Model is not supported by the selected provider',
      code: 'HF_PROVIDER_ERROR',
    });
  });

  it('returns Gemini-compatible response JSON containing quote-review-safe result text', async () => {
    const response = new Response(
      JSON.stringify({
        choices: [
          {
            message: {
              content: JSON.stringify({
                quotes: [
                  {
                    text: '  Marked\nquote\u0000text  ',
                    markingType: 'Margin Line!',
                    pageNumber: 5,
                    marginNote: '  Important\ncontext  ',
                    confidence: 1.4,
                  },
                ],
                pageNumber: 99_999,
                processingNotes: '  Model-assisted\nextraction  ',
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

    const normalized = await normalizeHuggingFaceQuoteResponse(response);
    const body = await normalized.json() as {
      candidates: Array<{ content: { parts: Array<{ text: string }> } }>;
    };
    const text = body.candidates[0]?.content.parts[0]?.text;

    expect(normalized.status).toBe(200);
    expect(JSON.parse(text ?? '{}')).toEqual({
      quotes: [
        {
          text: 'Marked quote text',
          markingType: 'margin_line',
          pageNumber: 5,
          marginNote: 'Important context',
          confidence: 1,
        },
      ],
      processingNotes: 'Model-assisted extraction',
    });
  });

  it('rejects malformed or unusable quote results before they reach the app', async () => {
    const response = new Response(
      JSON.stringify({
        choices: [
          {
            message: {
              content: JSON.stringify({
                quotes: [{ text: '   ', markingType: 'underline' }],
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

    const normalized = await normalizeHuggingFaceQuoteResponse(response);
    const body = await normalized.json() as { code: string };

    expect(normalized.status).toBe(502);
    expect(body.code).toBe('HF_INVALID_RESPONSE');
  });

  it('rejects more candidates than the quote review can display safely', async () => {
    const response = new Response(
      JSON.stringify({
        choices: [
          {
            message: {
              content: JSON.stringify({
                quotes: Array.from({ length: 31 }, (_, index) => ({
                  text: `Quote ${index + 1}`,
                  markingType: 'underline',
                })),
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

    const normalized = await normalizeHuggingFaceQuoteResponse(response);

    expect(normalized.status).toBe(502);
  });
});

describe('proxyToHuggingFaceQuoteExtractor', () => {
  it('calls the Hugging Face router with the backend token and normalized payload', async () => {
    const fetchSpy = vi.fn(async () => new Response(
      JSON.stringify({
        choices: [
          {
            message: {
              content: '{"quotes":[],"processingNotes":"none"}',
            },
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    ));
    vi.stubGlobal('fetch', fetchSpy);

    const response = await proxyToHuggingFaceQuoteExtractor(makeGeminiRequest(), {
      token: 'hf-test-token',
      modelId: 'Qwen/Qwen2.5-VL-72B-Instruct:featherless-ai',
    });

    expect(response.status).toBe(200);
    expect(fetchSpy).toHaveBeenCalledWith(
      'https://router.huggingface.co/v1/chat/completions',
      expect.objectContaining({
        method: 'POST',
        headers: {
          Authorization: 'Bearer hf-test-token',
          'Content-Type': 'application/json',
        },
      })
    );
  });
});
