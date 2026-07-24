import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {colours, sans, serif} from './theme';

export type CarouselSlideProps = {
  series: string;
  title: string;
  body: string;
  accent: string;
  screen?: string;
  kicker?: string;
  index: number;
  total: number;
};

export const carouselSets: Array<{
  id: string;
  series: string;
  slides: Omit<CarouselSlideProps, 'series' | 'index' | 'total'>[];
}> = [
  {
    id: 'Capture',
    series: 'Keep the lines you underlined',
    slides: [
      {
        kicker: 'A familiar reader problem',
        title: 'You marked the line for a reason.',
        body: 'But six months later, it is still trapped somewhere between two covers.',
        accent: colours.rust,
      },
      {
        kicker: 'Step 1',
        title: 'Add the book by ISBN.',
        body: 'Scan its barcode or enter the details manually. No AI photo guesswork for the cover.',
        accent: colours.navy,
      },
      {
        kicker: 'Step 2',
        title: 'Photograph the marked page.',
        body: 'AI extraction looks for the passage you marked. You review the result before it is saved.',
        accent: colours.gold,
      },
      {
        kicker: 'Step 3',
        title: 'Keep the words, not the photograph.',
        body: 'Save the quote to its book and find it again from your library.',
        accent: colours.green,
        screen: 'screens/library.png',
      },
    ],
  },
  {
    id: 'Library',
    series: 'Build a memory for your reading',
    slides: [
      {
        kicker: 'Your personal quote library',
        title: 'A bookshelf tells you what you read.',
        body: 'BookQuotes helps you remember what mattered.',
        accent: colours.green,
      },
      {
        kicker: 'Organise',
        title: 'Every quote stays with its book.',
        body: 'Keep titles, authors, reading status and saved passages together.',
        accent: colours.navy,
        screen: 'screens/library.png',
      },
      {
        kicker: 'Search',
        title: 'Find the thought, even when you forget the page.',
        body: 'Search across your books and saved quotes from one place.',
        accent: colours.rust,
        screen: 'screens/library.png',
      },
      {
        kicker: 'Use it',
        title: 'Return to the line when it matters.',
        body: 'For writing, reflection, conversation, or the simple pleasure of remembering.',
        accent: colours.gold,
      },
    ],
  },
  {
    id: 'Choice',
    series: 'A capture flow with a fallback',
    slides: [
      {
        kicker: 'How extraction works',
        title: 'AI first, when you choose it.',
        body: 'Subscribers can use remote AI extraction after agreeing to off-device image processing.',
        accent: colours.navy,
      },
      {
        kicker: 'Your choice',
        title: 'Review before anything joins your library.',
        body: 'Extraction is a starting point. You can correct the text before saving.',
        accent: colours.gold,
      },
      {
        kicker: 'When needed',
        title: 'On-device processing remains available.',
        body: 'If the network or remote service is unavailable, use the local fallback and keep moving.',
        accent: colours.green,
      },
      {
        kicker: 'Start reading forward',
        title: 'Your books. Your best lines.',
        body: 'BookQuotes is built for readers who underline, highlight and write in the margins.',
        accent: colours.rust,
        screen: 'screens/library.png',
      },
    ],
  },
];

export const CarouselSlide: React.FC<CarouselSlideProps> = ({
  series,
  title,
  body,
  accent,
  screen,
  kicker,
  index,
  total,
}) => (
  <AbsoluteFill style={{backgroundColor: colours.paper, padding: 58}}>
    <div
      style={{
        position: 'absolute',
        inset: 34,
        border: `2px solid ${colours.line}`,
      }}
    />
    <div
      style={{
        position: 'absolute',
        left: 34,
        right: 34,
        top: 34,
        height: 14,
        backgroundColor: accent,
      }}
    />
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        fontFamily: serif,
        color: colours.ink,
        fontSize: 34,
        fontWeight: 700,
        zIndex: 2,
      }}
    >
      <Img
        src={staticFile('assets/app-icon.png')}
        style={{width: 54, height: 54, borderRadius: 12}}
      />
      BookQuotes
    </div>
    <div
      style={{
        position: 'absolute',
        left: 76,
        right: screen ? 545 : 76,
        top: 245,
        zIndex: 2,
      }}
    >
      <div
        style={{
          color: accent,
          fontFamily: sans,
          fontSize: 23,
          fontWeight: 760,
          textTransform: 'uppercase',
          marginBottom: 30,
        }}
      >
        {kicker}
      </div>
      <div
        style={{
          color: colours.ink,
          fontFamily: serif,
          fontSize: screen ? 66 : 90,
          lineHeight: 1.04,
          fontWeight: 700,
        }}
      >
        {title}
      </div>
      <div
        style={{
          color: colours.muted,
          fontFamily: sans,
          fontSize: screen ? 29 : 35,
          lineHeight: 1.42,
          marginTop: 34,
        }}
      >
        {body}
      </div>
    </div>
    {screen ? (
      <div
        style={{
          position: 'absolute',
          width: 425,
          height: 925,
          right: 70,
          bottom: 92,
          padding: 8,
          borderRadius: 54,
          backgroundColor: colours.ink,
          border: `3px solid ${accent}`,
          boxShadow: '0 34px 70px rgba(23,26,31,0.2)',
          overflow: 'hidden',
          transform: 'rotate(1deg)',
        }}
      >
        <Img
          src={staticFile(screen)}
          style={{width: '100%', height: '100%', objectFit: 'cover', borderRadius: 44}}
        />
      </div>
    ) : (
      <div
        style={{
          position: 'absolute',
          left: 76,
          bottom: 190,
          width: 470,
          height: 12,
          backgroundColor: accent,
        }}
      />
    )}
    <div
      style={{
        position: 'absolute',
        left: 76,
        right: 76,
        bottom: 68,
        display: 'flex',
        justifyContent: 'space-between',
        color: colours.muted,
        fontFamily: sans,
        fontSize: 22,
        fontWeight: 650,
      }}
    >
      <span>{series}</span>
      <span>{index} / {total}</span>
    </div>
  </AbsoluteFill>
);
