import { describe, expect, it } from 'vitest';
import { sanitizeGeminiRequestPayload } from './gemini-proxy';

describe('sanitizeGeminiRequestPayload', () => {
  it('keeps only the supported prompt and single-image shape', () => {
    const body = sanitizeGeminiRequestPayload({
      contents: [
        {
          parts: [
            { text: '  extract the quote  ' },
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
        temperature: 0.9,
        maxOutputTokens: 999999,
      },
    });

    expect(body.contents).toHaveLength(1);
    expect(body.contents[0]?.parts).toHaveLength(2);
    expect(body.contents[0]?.parts[0]?.text).toBe('extract the quote');
    expect(body.generationConfig).toEqual({
      temperature: 0.1,
      maxOutputTokens: 4096,
      responseMimeType: 'application/json',
    });
  });

  it('rejects requests with multiple images', () => {
    expect(() =>
      sanitizeGeminiRequestPayload({
        contents: [
          {
            parts: [
              { text: 'extract' },
              { inlineData: { mimeType: 'image/jpeg', data: 'YQ==' } },
              { inlineData: { mimeType: 'image/jpeg', data: 'Yg==' } },
            ],
          },
        ],
      })
    ).toThrow('Request must contain one prompt and one image');
  });

  it('rejects oversized images', () => {
    expect(() =>
      sanitizeGeminiRequestPayload({
        contents: [
          {
            parts: [
              { text: 'extract' },
              {
                inlineData: {
                  mimeType: 'image/jpeg',
                  data: 'A'.repeat(6_100_000),
                },
              },
            ],
          },
        ],
      })
    ).toThrow('Image payload exceeds maximum size');
  });
});
