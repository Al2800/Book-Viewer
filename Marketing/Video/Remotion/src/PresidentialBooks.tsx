import React from 'react';
import {
  AbsoluteFill,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {BookOverviewHook} from './FeedCover';
import {colours, sans, serif} from './theme';

type PresidentialBook = {
  title: string;
  author: string;
  subject: string;
  readFor: string;
  description: string;
  commitment: string;
  cover: string;
  accent: string;
  dark: string;
};

export const presidentialBooks: PresidentialBook[] = [
  {
    title: 'Team of Rivals',
    author: 'Doris Kearns Goodwin',
    subject: 'Abraham Lincoln',
    readFor: "Lincoln's political intelligence",
    description: 'A multiple biography of the rivals he brought into his cabinet.',
    commitment: 'Long, but powered by personalities and conflict.',
    cover: 'assets/presidential-covers/team-of-rivals.jpg',
    accent: '#B75A44',
    dark: '#392622',
  },
  {
    title: 'The Years of Lyndon Johnson',
    author: 'Robert A. Caro',
    subject: 'Lyndon B. Johnson',
    readFor: 'How political power is actually built',
    description: 'Four published volumes, from the Texas Hill Country to the presidency.',
    commitment: 'The true commitment. Begin with The Path to Power.',
    cover: 'assets/presidential-covers/path-to-power.jpg',
    accent: '#C0923F',
    dark: '#3C321D',
  },
  {
    title: 'Washington: A Life',
    author: 'Ron Chernow',
    subject: 'George Washington',
    readFor: 'The person behind the monument',
    description: "Chernow's sweeping, Pulitzer-winning one-volume life.",
    commitment: 'A big book, and a clear all-life entry point.',
    cover: 'assets/presidential-covers/washington.jpg',
    accent: '#54768A',
    dark: '#24343D',
  },
  {
    title: 'Grant',
    author: 'Ron Chernow',
    subject: 'Ulysses S. Grant',
    readFor: 'Reinvention, war and Reconstruction',
    description: 'A life that rises from obscurity through the Civil War and presidency.',
    commitment: 'Especially good if your image of Grant stops at Appomattox.',
    cover: 'assets/presidential-covers/grant.jpg',
    accent: '#5D7A61',
    dark: '#27352A',
  },
  {
    title: 'Truman',
    author: 'David McCullough',
    subject: 'Harry S. Truman',
    readFor: 'An ordinary background meeting enormous decisions',
    description: "A vivid, Pulitzer-winning portrait of America's 33rd president.",
    commitment: 'Narrative history on a grand scale, not a quick primer.',
    cover: 'assets/presidential-covers/truman.jpg',
    accent: '#8D5C65',
    dark: '#38272B',
  },
];

const Paper: React.FC<{accent: string; children: React.ReactNode}> = ({
  accent,
  children,
}) => (
  <AbsoluteFill style={{backgroundColor: '#F3EFE5', color: colours.ink}}>
    <div
      style={{
        position: 'absolute',
        inset: 34,
        border: '2px solid #D4CCBE',
      }}
    />
    <div
      style={{
        position: 'absolute',
        left: 34,
        top: 34,
        bottom: 34,
        width: 15,
        backgroundColor: accent,
      }}
    />
    {children}
  </AbsoluteFill>
);

const Header: React.FC<{label: string}> = ({label}) => (
  <div
    style={{
      position: 'absolute',
      top: 76,
      left: 84,
      right: 84,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      fontFamily: sans,
      fontSize: 24,
      fontWeight: 800,
      color: colours.muted,
      textTransform: 'uppercase',
    }}
  >
    <span>BookQuotes reading list</span>
    <span>{label}</span>
  </div>
);

const Footer: React.FC = () => (
  <div
    style={{
      position: 'absolute',
      left: 84,
      right: 84,
      bottom: 78,
      display: 'flex',
      justifyContent: 'space-between',
      fontFamily: sans,
      fontSize: 23,
      fontWeight: 750,
      color: colours.muted,
    }}
  >
    <span>@bookquotes.app</span>
    <span>Save for your reading list</span>
  </div>
);

const BookJacket: React.FC<{
  book: PresidentialBook;
  compact?: boolean;
  motion?: number;
}> = ({book, compact = false, motion = 1}) => {
  const width = compact ? 390 : 454;
  const height = compact ? 590 : 684;

  return (
    <div
      style={{
        position: 'relative',
        width,
        height,
        flexShrink: 0,
        backgroundColor: '#E5DED1',
        border: '5px solid #FFFDF8',
        boxShadow: '0 32px 66px rgba(24, 27, 31, 0.22)',
        transform: `translateY(${interpolate(motion, [0, 1], [70, 0])}px) rotate(-2deg)`,
      }}
    >
      <Img
        src={staticFile(book.cover)}
        style={{
          width: '100%',
          height: '100%',
          display: 'block',
          objectFit: 'contain',
        }}
      />
    </div>
  );
};

export type PresidentialBookSlideProps =
  | {kind: 'cover'}
  | {kind: 'book'; bookIndex: number}
  | {kind: 'end'};

const CoverSlide: React.FC = () => (
  <Paper accent={colours.rust}>
    <Header label="01 / 07" />
    <div
      style={{
        position: 'absolute',
        left: 84,
        right: 82,
        top: 270,
      }}
    >
      <div
        style={{
          maxWidth: 840,
          fontFamily: serif,
          fontSize: 116,
          lineHeight: 0.98,
          fontWeight: 700,
        }}
      >
        5 presidential biographies worth the commitment
      </div>
      <div
        style={{
          marginTop: 56,
          maxWidth: 790,
          paddingLeft: 28,
          borderLeft: `9px solid ${colours.rust}`,
          fontFamily: sans,
          fontSize: 34,
          lineHeight: 1.4,
          fontWeight: 650,
          color: colours.navy,
        }}
      >
        Five very different ways into leadership, character and American power.
      </div>
    </div>
    <div
      style={{
        position: 'absolute',
        right: 74,
        bottom: 194,
        fontFamily: serif,
        fontSize: 245,
        lineHeight: 0.8,
        fontWeight: 700,
        color: colours.rust,
        opacity: 0.14,
      }}
    >
      05
    </div>
    <Footer />
  </Paper>
);

const BookSlide: React.FC<{bookIndex: number}> = ({bookIndex}) => {
  const book = presidentialBooks[bookIndex];

  return (
    <Paper accent={book.accent}>
      <Header label={`${String(bookIndex + 2).padStart(2, '0')} / 07`} />
      <div
        style={{
          position: 'absolute',
          top: 214,
          left: 84,
          right: 80,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          gap: 46,
        }}
      >
        <BookJacket book={book} compact />
        <div style={{paddingTop: 24, flex: 1}}>
          <div
            style={{
              fontFamily: sans,
              fontSize: 22,
              fontWeight: 850,
              color: book.accent,
              textTransform: 'uppercase',
            }}
          >
            {bookIndex + 1} of 5 · {book.subject}
          </div>
          <div
            style={{
              marginTop: 24,
              fontFamily: serif,
              fontSize: 61,
              lineHeight: 1.03,
              fontWeight: 700,
            }}
          >
            Read this for:
          </div>
          <div
            style={{
              marginTop: 13,
              fontFamily: serif,
              fontSize: 58,
              lineHeight: 1.04,
              fontWeight: 700,
              color: book.accent,
            }}
          >
            {book.readFor}
          </div>
        </div>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 84,
          right: 84,
          top: 890,
          paddingTop: 46,
          borderTop: `2px solid ${colours.line}`,
        }}
      >
        <div
          style={{
            maxWidth: 850,
            fontFamily: serif,
            fontSize: 51,
            lineHeight: 1.24,
            fontWeight: 650,
          }}
        >
          {book.description}
        </div>
        <div
          style={{
            marginTop: 44,
            display: 'inline-block',
            padding: '23px 28px',
            backgroundColor: book.dark,
            fontFamily: sans,
            fontSize: 28,
            lineHeight: 1.35,
            fontWeight: 730,
            color: '#FFFDF8',
          }}
        >
          Know before you start: {book.commitment}
        </div>
      </div>
      <Footer />
    </Paper>
  );
};

const EndSlide: React.FC = () => (
  <Paper accent={colours.gold}>
    <Header label="07 / 07" />
    <div
      style={{
        position: 'absolute',
        inset: '260px 84px 210px',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        textAlign: 'center',
      }}
    >
      <div
        style={{
          fontFamily: serif,
          fontSize: 108,
          lineHeight: 1,
          fontWeight: 700,
        }}
      >
        Which one belongs on your reading list?
      </div>
      <div
        style={{
          margin: '58px auto 0',
          width: 180,
          height: 10,
          backgroundColor: colours.gold,
        }}
      />
      <div
        style={{
          marginTop: 52,
          fontFamily: sans,
          fontSize: 34,
          lineHeight: 1.45,
          fontWeight: 650,
          color: colours.navy,
        }}
      >
        And which presidential biography did we miss?
      </div>
    </div>
    <Footer />
  </Paper>
);

export const PresidentialBookSlide: React.FC<PresidentialBookSlideProps> = (props) => {
  if (props.kind === 'cover') {
    return <CoverSlide />;
  }
  if (props.kind === 'end') {
    return <EndSlide />;
  }
  return <BookSlide bookIndex={props.bookIndex} />;
};

const ReelCover: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 8, 90, 105], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{opacity}}>
      <BookOverviewHook
        hook="5 biographies"
        kicker="worth the commitment"
        title="Lincoln, Johnson, Washington, Grant, Truman"
        label="Reading list"
        field="rust"
        accent={colours.gold}
        object="jacket"
        jacket="assets/presidential-covers/team-of-rivals.jpg"
        book={{
          title: 'Team of Rivals',
          author: 'Doris Kearns Goodwin',
          jacket: 'assets/presidential-covers/team-of-rivals.jpg',
          status: 'Reader pick',
          collection: 'Presidential biographies',
          note: "Lincoln's political intelligence, and the rivals he brought into cabinet.",
        }}
      />
    </AbsoluteFill>
  );
};

const ReelBook: React.FC<{bookIndex: number}> = ({bookIndex}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const book = presidentialBooks[bookIndex];
  const entrance = spring({frame, fps, config: {damping: 20, stiffness: 100}});

  return (
    <Paper accent={book.accent}>
      <Header label={`${bookIndex + 1} of 5`} />
      <div
        style={{
          position: 'absolute',
          top: 220,
          left: 84,
          right: 80,
          display: 'flex',
          alignItems: 'center',
          gap: 64,
        }}
      >
        <BookJacket book={book} motion={entrance} />
        <div style={{flex: 1}}>
          <div
            style={{
              fontFamily: sans,
              fontSize: 23,
              fontWeight: 850,
              color: book.accent,
              textTransform: 'uppercase',
            }}
          >
            {book.subject}
          </div>
          <div
            style={{
              marginTop: 28,
              fontFamily: serif,
              fontSize: 64,
              lineHeight: 1.03,
              fontWeight: 700,
            }}
          >
            Read for
          </div>
          <div
            style={{
              marginTop: 10,
              fontFamily: serif,
              fontSize: 57,
              lineHeight: 1.05,
              fontWeight: 700,
              color: book.accent,
            }}
          >
            {book.readFor}
          </div>
        </div>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 84,
          right: 84,
          top: 1000,
          paddingTop: 48,
          borderTop: `2px solid ${colours.line}`,
          transform: `translateY(${interpolate(entrance, [0, 1], [40, 0])}px)`,
        }}
      >
        <div style={{fontFamily: serif, fontSize: 51, lineHeight: 1.25, fontWeight: 650}}>
          {book.description}
        </div>
        <div
          style={{
            marginTop: 42,
            fontFamily: sans,
            fontSize: 28,
            lineHeight: 1.4,
            fontWeight: 700,
            color: colours.muted,
          }}
        >
          {book.commitment}
        </div>
      </div>
      <Footer />
    </Paper>
  );
};

const ReelEnd: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 18, stiffness: 100}});

  return (
    <Paper accent={colours.gold}>
      <div
        style={{
          position: 'absolute',
          inset: '260px 82px 220px',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          textAlign: 'center',
          transform: `scale(${interpolate(entrance, [0, 1], [0.92, 1])})`,
        }}
      >
        <div style={{fontFamily: serif, fontSize: 106, lineHeight: 1, fontWeight: 700}}>
          Which one are you reading?
        </div>
        <div
          style={{
            marginTop: 52,
            fontFamily: sans,
            fontSize: 35,
            lineHeight: 1.45,
            fontWeight: 650,
            color: colours.navy,
          }}
        >
          Tell us the presidential biography that deserves part two.
        </div>
      </div>
      <Footer />
    </Paper>
  );
};

export const PresidentialBooksReel: React.FC = () => (
  <AbsoluteFill>
    <Sequence from={0} durationInFrames={105}>
      <ReelCover />
    </Sequence>
    {presidentialBooks.map((_, index) => (
      <Sequence key={index} from={90 + index * 132} durationInFrames={147}>
        <ReelBook bookIndex={index} />
      </Sequence>
    ))}
    <Sequence from={750} durationInFrames={120}>
      <ReelEnd />
    </Sequence>
  </AbsoluteFill>
);
