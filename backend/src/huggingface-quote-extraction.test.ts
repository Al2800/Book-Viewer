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
      modelId: 'Qwen/Qwen2.5-VL-72B-Instruct:hf-inference',
    });

    expect(body.model).toBe('Qwen/Qwen2.5-VL-72B-Instruct:hf-inference');
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
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct:hf-inference'))
      .toBe('Qwen/Qwen2.5-VL-72B-Instruct:hf-inference');
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct:preferred')).toBeNull();
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct:fastest')).toBeNull();
    expect(resolveApprovedHuggingFaceModelId('Qwen/Qwen2.5-VL-72B-Instruct')).toBeNull();
  });
});

describe('normalizeHuggingFaceQuoteResponse', () => {
  it('returns Gemini-compatible response JSON containing normalized quote result text', async () => {
    const response = new Response(
      JSON.stringify({
        choices: [
          {
            message: {
              content: JSON.stringify({
                quotes: [
                  {
                    text: 'Marked quote text',
                    markingType: 'underline',
                    confidence: 0.88,
                  },
                ],
                processingNotes: 'Model-assisted extraction',
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
          markingType: 'underline',
          confidence: 0.88,
        },
      ],
      processingNotes: 'Model-assisted extraction',
    });
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
      modelId: 'Qwen/Qwen2.5-VL-72B-Instruct:hf-inference',
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
