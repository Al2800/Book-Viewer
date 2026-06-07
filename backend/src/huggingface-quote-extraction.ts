import type { GeminiRequest } from './types';

const HUGGING_FACE_ROUTER_URL = 'https://router.huggingface.co/v1/chat/completions';
const DEFAULT_MODEL_ID = 'Qwen/Qwen2.5-VL-72B-Instruct:preferred';

const QUOTE_EXTRACTION_SYSTEM_PROMPT = [
  'You extract marked passages from photographed book pages.',
  'Identify only text indicated by underlines, highlights, brackets, or vertical margin marks.',
  'Return strict JSON with keys: quotes, pageNumber, processingNotes.',
  'Each quote must include text, markingType, confidence, and optional pageNumber or marginNote.',
  'Do not invent text. If no marked passage is readable, return {"quotes":[]}.',
].join(' ');

export interface HuggingFaceQuoteConfig {
  modelId?: string;
}

export interface HuggingFaceProxyConfig extends HuggingFaceQuoteConfig {
  token: string;
}

interface HuggingFaceMessageContentText {
  type: 'text';
  text: string;
}

interface HuggingFaceMessageContentImage {
  type: 'image_url';
  image_url: {
    url: string;
  };
}

type HuggingFaceMessageContent =
  | string
  | Array<HuggingFaceMessageContentText | HuggingFaceMessageContentImage>;

interface HuggingFaceMessage {
  role: 'system' | 'user';
  content: HuggingFaceMessageContent;
}

interface HuggingFaceChatCompletionRequest {
  model: string;
  messages: HuggingFaceMessage[];
  temperature: number;
  max_tokens: number;
  response_format: {
    type: 'json_object';
  };
}

interface HuggingFaceChatCompletionResponse {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
}

export function buildHuggingFaceQuoteRequest(
  request: GeminiRequest,
  config: HuggingFaceQuoteConfig = {}
): HuggingFaceChatCompletionRequest {
  const { prompt, image } = extractPromptAndImage(request);

  return {
    model: config.modelId ?? DEFAULT_MODEL_ID,
    temperature: 0.1,
    max_tokens: 4096,
    response_format: { type: 'json_object' },
    messages: [
      {
        role: 'system',
        content: QUOTE_EXTRACTION_SYSTEM_PROMPT,
      },
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: prompt,
          },
          {
            type: 'image_url',
            image_url: {
              url: `data:${image.mimeType};base64,${image.data}`,
            },
          },
        ],
      },
    ],
  };
}

export async function proxyToHuggingFaceQuoteExtractor(
  request: GeminiRequest,
  config: HuggingFaceProxyConfig
): Promise<Response> {
  const response = await fetch(HUGGING_FACE_ROUTER_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(buildHuggingFaceQuoteRequest(request, config)),
  });

  return normalizeHuggingFaceQuoteResponse(response);
}

export async function normalizeHuggingFaceQuoteResponse(response: Response): Promise<Response> {
  const responseText = await response.text();

  if (!response.ok) {
    return new Response(responseText, {
      status: response.status,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  let completion: HuggingFaceChatCompletionResponse;
  try {
    completion = JSON.parse(responseText) as HuggingFaceChatCompletionResponse;
  } catch {
    return invalidHuggingFaceResponse('Malformed Hugging Face response');
  }

  const content = completion.choices?.[0]?.message?.content?.trim();
  if (!content) {
    return invalidHuggingFaceResponse('No content in Hugging Face response');
  }

  return new Response(JSON.stringify({
    candidates: [
      {
        content: {
          parts: [
            { text: content },
          ],
        },
        finishReason: 'STOP',
      },
    ],
  }), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

function extractPromptAndImage(request: GeminiRequest): {
  prompt: string;
  image: { mimeType: string; data: string };
} {
  const parts = request.contents[0]?.parts ?? [];
  const prompt = parts.find((part) => part.text !== undefined)?.text;
  const image = parts.find((part) => part.inlineData !== undefined)?.inlineData;

  if (!prompt || !image) {
    throw new Error('Request must include one prompt and one image');
  }

  return { prompt, image };
}

function invalidHuggingFaceResponse(message: string): Response {
  return new Response(JSON.stringify({
    error: message,
    code: 'HF_INVALID_RESPONSE',
  }), {
    status: 502,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}
