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
  {
    id: 'Remember',
    series: 'How to remember more of what you read',
    slides: [
      {
        kicker: 'A useful reading habit',
        title: 'Do not highlight everything.',
        body: 'Mark the sentence that changes, clarifies or names something for you.',
        accent: colours.rust,
      },
      {
        kicker: 'After the chapter',
        title: 'Write five words about why.',
        body: 'A tiny note preserves the connection that made the passage matter.',
        accent: colours.gold,
      },
      {
        kicker: 'After the book',
        title: 'Choose the five lines that survived.',
        body: 'A smaller collection is easier to revisit than a complete archive.',
        accent: colours.green,
      },
      {
        kicker: 'Once a week',
        title: 'Bring one old line back.',
        body: 'Use it in a conversation, a journal entry, or something you are making.',
        accent: colours.navy,
      },
    ],
  },
  {
    id: 'OneLine',
    series: 'The one-line summer reading challenge',
    slides: [
      {
        kicker: 'National Year of Reading 2026',
        title: 'One book. One line.',
        body: 'This summer, keep one passage from every book you finish.',
        accent: colours.gold,
      },
      {
        kicker: 'Choose slowly',
        title: 'Not the most impressive line.',
        body: 'Choose the one you found yourself thinking about the next day.',
        accent: colours.rust,
      },
      {
        kicker: 'Keep the context',
        title: 'Title, author, page, and why.',
        body: 'Those four details turn a quotation into part of your reading memory.',
        accent: colours.navy,
      },
      {
        kicker: 'Your summer in words',
        title: 'What will your collection say?',
        body: 'Share the first line you would keep, or start a private library of your own.',
        accent: colours.green,
        screen: 'screens/appstore/iphone/03_quote_detail.png',
      },
    ],
  },
  {
    id: 'BookClub',
    series: 'A better book-club note',
    slides: [
      {
        kicker: 'Before the meeting',
        title: 'Bring three passages, not a plot summary.',
        body: 'A specific line gives everyone something real to respond to.',
        accent: colours.navy,
      },
      {
        kicker: 'Passage one',
        title: 'The line you loved.',
        body: 'What did the language make you notice or feel?',
        accent: colours.gold,
      },
      {
        kicker: 'Passage two',
        title: 'The line you resisted.',
        body: 'Disagreement often opens a better conversation than consensus.',
        accent: colours.rust,
      },
      {
        kicker: 'Passage three',
        title: 'The line you are still unsure about.',
        body: 'A good book-club question does not need a finished answer.',
        accent: colours.green,
      },
    ],
  },
  {
    id: 'Annotation',
    series: 'What does a loved book look like?',
    slides: [
      {
        kicker: 'Reader roll call',
        title: 'The underliner.',
        body: 'Direct. Permanent. The sentence has been chosen.',
        accent: colours.rust,
      },
      {
        kicker: 'Reader roll call',
        title: 'The tabber.',
        body: 'Colour-coded feelings with a system nobody else fully understands.',
        accent: colours.gold,
      },
      {
        kicker: 'Reader roll call',
        title: 'The margin writer.',
        body: 'Part reader, part conversational partner, occasionally an editor.',
        accent: colours.green,
      },
      {
        kicker: 'Reader roll call',
        title: 'The pristine-page protector.',
        body: 'No marks. No folds. Notes kept safely somewhere else. Which are you?',
        accent: colours.navy,
      },
    ],
  },
  {
    id: 'Commonplace',
    series: 'A ten-minute commonplace ritual',
    slides: [
      {
        kicker: 'Once a week',
        title: 'Choose three marked lines.',
        body: 'Take only the passages that still feel useful, beautiful or unresolved.',
        accent: colours.green,
      },
      {
        kicker: 'Add context',
        title: 'Write one sentence about each.',
        body: 'Why did it matter then, and where might it matter again?',
        accent: colours.rust,
      },
      {
        kicker: 'Make it retrievable',
        title: 'Keep the book and page with the words.',
        body: 'Future you should be able to return to the source.',
        accent: colours.navy,
        screen: 'screens/appstore/iphone/02_book_detail.png',
      },
      {
        kicker: 'Complete the loop',
        title: 'Revisit one old passage.',
        body: 'A commonplace book earns its value when an idea returns at the right moment.',
        accent: colours.gold,
        screen: 'screens/appstore/iphone/04_search_results.png',
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
