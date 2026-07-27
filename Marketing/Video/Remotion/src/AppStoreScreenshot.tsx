import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {colours, sans, serif} from './theme';

export type AppStoreScreenshotProps = {
  title: string;
  body: string;
  accent: string;
  screen: string;
  step: number;
  total: number;
  device: 'iphone' | 'ipad';
};

const IphoneFrame: React.FC<{screen: string; accent: string}> = ({screen, accent}) => (
  <div
    style={{
      position: 'absolute',
      left: 116,
      width: 1088,
      top: 690,
      height: 2365,
      padding: 14,
      borderRadius: 92,
      backgroundColor: colours.ink,
      border: `4px solid ${accent}`,
      boxShadow: '0 42px 90px rgba(23,26,31,0.24)',
      overflow: 'hidden',
    }}
  >
    <Img
      src={staticFile(screen)}
      style={{
        width: '100%',
        height: '100%',
        objectFit: 'cover',
        objectPosition: 'top',
        borderRadius: 76,
      }}
    />
  </div>
);

const IpadFrame: React.FC<{screen: string; accent: string}> = ({screen, accent}) => {
  const focusesCaptureReview = screen.includes('06_captured_page');

  return (
    <div
      style={{
        position: 'absolute',
        left: 126,
        right: 126,
        top: 610,
        height: 2350,
        padding: 14,
        borderRadius: 78,
        backgroundColor: colours.ink,
        border: `4px solid ${accent}`,
        boxShadow: '0 42px 90px rgba(23,26,31,0.22)',
        overflow: 'hidden',
      }}
    >
      <Img
        src={staticFile(screen)}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          objectPosition: 'top',
          borderRadius: 62,
          transform: focusesCaptureReview ? 'scale(1.42)' : undefined,
          transformOrigin: focusesCaptureReview ? '50% 58%' : undefined,
        }}
      />
    </div>
  );
};

export const AppStoreScreenshot: React.FC<AppStoreScreenshotProps> = ({
  title,
  body,
  accent,
  screen,
  step,
  total,
  device,
}) => {
  const ipad = device === 'ipad';

  return (
    <AbsoluteFill style={{backgroundColor: colours.paper, overflow: 'hidden'}}>
      <div
        style={{
          position: 'absolute',
          inset: ipad ? 48 : 34,
          border: `2px solid ${colours.line}`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: ipad ? 48 : 34,
          right: ipad ? 48 : 34,
          top: ipad ? 48 : 34,
          height: ipad ? 18 : 16,
          backgroundColor: accent,
        }}
      />

      <div
        style={{
          position: 'absolute',
          left: ipad ? 112 : 82,
          right: ipad ? 112 : 82,
          top: ipad ? 98 : 78,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div style={{display: 'flex', alignItems: 'center', gap: ipad ? 22 : 16}}>
          <Img
            src={staticFile('assets/app-icon.png')}
            style={{
              width: ipad ? 78 : 62,
              height: ipad ? 78 : 62,
              borderRadius: ipad ? 18 : 14,
            }}
          />
          <span
            style={{
              color: colours.ink,
              fontFamily: serif,
              fontSize: ipad ? 46 : 38,
              fontWeight: 700,
            }}
          >
            BookQuotes
          </span>
        </div>
        <span
          style={{
            color: accent,
            fontFamily: sans,
            fontSize: ipad ? 28 : 24,
            fontWeight: 760,
          }}
        >
          {String(step).padStart(2, '0')} / {String(total).padStart(2, '0')}
        </span>
      </div>

      <div
        style={{
          position: 'absolute',
          left: ipad ? 112 : 82,
          right: ipad ? 112 : 82,
          top: ipad ? 218 : 190,
        }}
      >
        <div
          style={{
            color: colours.ink,
            fontFamily: serif,
            fontSize: ipad ? 96 : 90,
            lineHeight: 1.02,
            fontWeight: 700,
            maxWidth: ipad ? 1600 : 1120,
          }}
        >
          {title}
        </div>
        <div
          style={{
            color: colours.muted,
            fontFamily: sans,
            fontSize: ipad ? 35 : 31,
            lineHeight: 1.35,
            marginTop: ipad ? 20 : 18,
            maxWidth: ipad ? 1640 : 1120,
          }}
        >
          {body}
        </div>
      </div>

      {ipad ? <IpadFrame screen={screen} accent={accent} /> : <IphoneFrame screen={screen} accent={accent} />}
    </AbsoluteFill>
  );
};

export const appStoreScreenshots = [
  {
    id: 'Library',
    title: 'Keep the lines you underlined.',
    body: 'Turn marked paper pages into a searchable personal quote library.',
    accent: colours.rust,
    source: '01_library_grid.png',
  },
  {
    id: 'ISBN',
    title: 'Scan the ISBN. Get the book.',
    body: 'Add the title, author and cover without retyping catalogue details.',
    accent: colours.navy,
    source: '05_add_book_isbn.png',
  },
  {
    id: 'Capture',
    title: 'Photograph the passage you marked.',
    body: 'Check focus and framing before extraction begins.',
    accent: colours.gold,
    source: '06_captured_page.png',
  },
  {
    id: 'Extraction',
    title: 'AI finds the marked words.',
    body: 'See the extracted passage and its source before anything is saved.',
    accent: colours.green,
    source: '07_extraction_review.png',
  },
  {
    id: 'Review',
    title: 'Review every word.',
    body: 'Correct the text, page number or note while you stay in control.',
    accent: colours.rust,
    source: '03_quote_detail.png',
  },
  {
    id: 'Book',
    title: 'Keep every passage with its book.',
    body: 'Saved quotes remain organised by title, author and page.',
    accent: colours.navy,
    source: '02_book_detail.png',
  },
  {
    id: 'Search',
    title: 'Find the line when it matters.',
    body: 'Search across books and saved quotes from one place.',
    accent: colours.green,
    source: '04_search_results.png',
  },
] as const;
