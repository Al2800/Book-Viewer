import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {colours, coverBone, coverFields, sans, serif} from './theme';

export type CoverField = keyof typeof coverFields;
export type CoverObject = 'page' | 'marks' | 'journal' | 'fragment' | 'jacket' | 'pair';

export type BookOverview = {
  title: string;
  author: string;
  jacket: string;
  status?: string;
  collection?: string;
  note?: string;
};

export type FeedCoverProps = {
  hook: string;
  kicker?: string;
  title?: string;
  label?: string;
  field: CoverField;
  accent: string;
  object: CoverObject;
  jacket?: string;
  pair?: [string, string];
  screen?: string;
  book?: BookOverview;
  showBrand?: boolean;
};

export type FeedCoverEntry = {
  id: string;
  output: string;
  props: FeedCoverProps;
};

const hookSize = (hook: string) => {
  if (hook.length <= 16) {
    return 118;
  }
  if (hook.length <= 28) {
    return 96;
  }
  return 78;
};

const Field: React.FC<{field: CoverField; accent: string}> = ({field, accent}) => (
  <AbsoluteFill style={{backgroundColor: coverFields[field]}}>
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: `radial-gradient(circle at 50% 42%, ${accent}26 0%, transparent 46%)`,
      }}
    />
    <div
      style={{
        position: 'absolute',
        inset: 28,
        border: `1px solid ${coverBone}14`,
      }}
    />
  </AbsoluteFill>
);

const PageCard: React.FC<{
  width: number;
  height: number;
  rotate: number;
  accent: string;
  kind: 'underline' | 'tab' | 'clean' | 'journal' | 'fragment';
}> = ({width, height, rotate, accent, kind}) => (
  <div
    style={{
      width,
      height,
      backgroundColor: colours.paper,
      borderRadius: 5,
      boxShadow: '0 28px 64px rgba(0,0,0,0.42)',
      transform: `rotate(${rotate}deg)`,
      padding: kind === 'fragment' ? '36px 32px 28px' : '34px 30px 26px',
      overflow: 'hidden',
    }}
  >
    {[0, 1, 2, 3, 4].map((index) => (
      <div
        key={index}
        style={{
          height: 7,
          marginBottom: 18,
          width: index === 4 ? '58%' : `${88 - index * 4}%`,
          backgroundColor: '#D3CBBA',
          opacity: kind === 'clean' && index === 2 ? 0.35 : 1,
        }}
      />
    ))}
    {kind === 'underline' ? (
      <div
        style={{
          marginTop: -8,
          height: 8,
          width: '72%',
          backgroundColor: accent,
        }}
      />
    ) : null}
    {kind === 'tab' ? (
      <div
        style={{
          position: 'absolute',
          right: -2,
          top: 86,
          width: 18,
          height: 46,
          backgroundColor: accent,
          borderRadius: '4px 0 0 4px',
        }}
      />
    ) : null}
    {kind === 'journal' ? (
      <div
        style={{
          marginTop: 8,
          paddingLeft: 16,
          borderLeft: `6px solid ${accent}`,
          fontFamily: sans,
          fontSize: 22,
          fontWeight: 750,
          color: colours.navy,
        }}
      >
        three lines. one why.
      </div>
    ) : null}
    {kind === 'fragment' ? (
      <div
        style={{
          marginTop: 10,
          fontFamily: serif,
          fontSize: 28,
          lineHeight: 1.15,
          fontWeight: 700,
          color: colours.ink,
        }}
      >
        the line, not the page
      </div>
    ) : null}
  </div>
);

const CoverObject: React.FC<Pick<FeedCoverProps, 'object' | 'accent' | 'jacket' | 'pair'>> = ({
  object,
  accent,
  jacket,
  pair,
}) => {
  if (object === 'jacket' && jacket) {
    return (
      <div
        style={{
          width: 320,
          height: 488,
          padding: 10,
          backgroundColor: colours.white,
          boxShadow: '0 32px 70px rgba(0,0,0,0.5)',
          transform: 'rotate(-4deg)',
        }}
      >
        <Img
          src={staticFile(jacket)}
          style={{width: '100%', height: '100%', objectFit: 'cover', display: 'block'}}
        />
      </div>
    );
  }

  if (object === 'marks') {
    return (
      <div style={{display: 'flex', gap: 22, alignItems: 'flex-end'}}>
        <PageCard width={186} height={248} rotate={-8} accent={colours.rust} kind="underline" />
        <PageCard width={186} height={248} rotate={2} accent={colours.gold} kind="tab" />
        <PageCard width={186} height={248} rotate={7} accent={colours.navy} kind="clean" />
      </div>
    );
  }

  if (object === 'pair' && pair) {
    return (
      <div style={{display: 'flex', gap: 28}}>
        {pair.map((item, index) => (
          <div
            key={item}
            style={{
              width: 280,
              height: 210,
              backgroundColor: index === 0 ? '#1E2A24' : '#2A2228',
              border: `2px solid ${accent}88`,
              borderRadius: 8,
              padding: '28px 24px',
              transform: `rotate(${index === 0 ? -5 : 5}deg)`,
              boxShadow: '0 22px 48px rgba(0,0,0,0.35)',
            }}
          >
            <div
              style={{
                fontFamily: sans,
                fontSize: 18,
                fontWeight: 800,
                color: accent,
                textTransform: 'uppercase',
              }}
            >
              {index === 0 ? 'Route one' : 'Route two'}
            </div>
            <div
              style={{
                marginTop: 16,
                fontFamily: serif,
                fontSize: 36,
                lineHeight: 1.05,
                fontWeight: 700,
                color: coverBone,
              }}
            >
              {item}
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (object === 'journal') {
    return (
      <PageCard width={620} height={360} rotate={-4} accent={accent} kind="journal" />
    );
  }

  if (object === 'fragment') {
    return (
      <PageCard width={560} height={300} rotate={-6} accent={accent} kind="fragment" />
    );
  }

  return <PageCard width={600} height={340} rotate={-5} accent={accent} kind="underline" />;
};

export const PhoneFrame: React.FC<{
  screen?: string;
  accent: string;
  width?: number;
  height?: number;
  children?: React.ReactNode;
}> = ({screen, accent, width = 505, height = 1096, children}) => (
  <div
    style={{
      position: 'relative',
      width,
      height,
      padding: 10,
      borderRadius: 67,
      backgroundColor: '#1d212a',
      border: `2px solid ${accent}aa`,
      boxShadow: '0 50px 110px rgba(0,0,0,0.68)',
      overflow: 'hidden',
    }}
  >
    <div
      style={{
        position: 'absolute',
        left: '50%',
        top: 20,
        width: 152,
        height: 38,
        marginLeft: -76,
        borderRadius: 24,
        backgroundColor: '#000',
        zIndex: 5,
      }}
    />
    {children ?? (screen ? (
      <Img
        src={staticFile(screen)}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          objectPosition: 'top',
          borderRadius: 56,
        }}
      />
    ) : null)}
  </div>
);

const BookOverviewScreen: React.FC<{book: BookOverview}> = ({book}) => (
  <div
    style={{
      width: '100%',
      height: '100%',
      backgroundColor: colours.paper,
      borderRadius: 56,
      overflow: 'hidden',
      color: colours.ink,
      display: 'flex',
      flexDirection: 'column',
      padding: '54px 22px 28px',
      boxSizing: 'border-box',
    }}
  >
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        fontFamily: sans,
        fontSize: 16,
        fontWeight: 700,
        color: colours.muted,
        padding: '0 8px 18px',
      }}
    >
      <span>10:05</span>
      <span>5G  ▮▮▮</span>
    </div>
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 22,
      }}
    >
      <div
        style={{
          width: 36,
          height: 36,
          borderRadius: 18,
          backgroundColor: colours.white,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: sans,
          fontSize: 28,
          lineHeight: 1,
          color: colours.ink,
        }}
      >
        ‹
      </div>
      <div
        style={{
          flex: 1,
          padding: '0 12px',
          fontFamily: serif,
          fontSize: 22,
          fontWeight: 700,
          textAlign: 'center',
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}
      >
        {book.title}
      </div>
      <div
        style={{
          width: 36,
          height: 36,
          borderRadius: 18,
          backgroundColor: colours.white,
        }}
      />
    </div>
    <div
      style={{
        backgroundColor: colours.white,
        borderRadius: 28,
        padding: 18,
        display: 'flex',
        gap: 16,
        boxShadow: '0 10px 24px rgba(23,26,31,0.06)',
      }}
    >
      <Img
        src={staticFile(book.jacket)}
        style={{
          width: 112,
          height: 168,
          objectFit: 'cover',
          borderRadius: 8,
          flexShrink: 0,
        }}
      />
      <div style={{minWidth: 0, paddingTop: 6}}>
        <div
          style={{
            fontFamily: serif,
            fontSize: 26,
            lineHeight: 1.1,
            fontWeight: 700,
          }}
        >
          {book.title}
        </div>
        <div
          style={{
            marginTop: 8,
            fontFamily: sans,
            fontSize: 18,
            fontWeight: 650,
            color: colours.muted,
          }}
        >
          {book.author}
        </div>
        {book.collection ? (
          <div
            style={{
              marginTop: 8,
              fontFamily: sans,
              fontSize: 15,
              color: colours.muted,
            }}
          >
            {book.collection}
          </div>
        ) : null}
        {book.status ? (
          <div
            style={{
              display: 'inline-block',
              marginTop: 12,
              padding: '6px 10px',
              borderRadius: 999,
              backgroundColor: '#EEE8DC',
              fontFamily: sans,
              fontSize: 13,
              fontWeight: 750,
              color: colours.navy,
            }}
          >
            {book.status}
          </div>
        ) : null}
      </div>
    </div>
    <div style={{display: 'flex', gap: 10, marginTop: 14}}>
      {[
        ['1', 'Note'],
        ['Keep', 'With the book'],
      ].map(([value, label]) => (
        <div
          key={label}
          style={{
            flex: 1,
            backgroundColor: colours.white,
            borderRadius: 20,
            padding: '14px 12px',
            boxShadow: '0 8px 18px rgba(23,26,31,0.05)',
          }}
        >
          <div style={{fontFamily: sans, fontSize: 20, fontWeight: 780}}>{value}</div>
          <div style={{marginTop: 4, fontFamily: sans, fontSize: 14, color: colours.muted}}>
            {label}
          </div>
        </div>
      ))}
    </div>
    {book.note ? (
      <div
        style={{
          marginTop: 14,
          backgroundColor: colours.white,
          borderRadius: 24,
          padding: '20px 18px 16px',
          boxShadow: '0 10px 24px rgba(23,26,31,0.06)',
        }}
      >
        <div
          style={{
            fontFamily: serif,
            fontSize: 24,
            lineHeight: 1.28,
            fontWeight: 650,
          }}
        >
          {book.note}
        </div>
        <div
          style={{
            marginTop: 16,
            display: 'flex',
            alignItems: 'center',
            gap: 8,
          }}
        >
          <div
            style={{
              padding: '5px 10px',
              borderRadius: 999,
              backgroundColor: '#F3D9D2',
              fontFamily: sans,
              fontSize: 13,
              fontWeight: 750,
              color: colours.rust,
            }}
          >
            Note
          </div>
        </div>
      </div>
    ) : null}
    <div style={{flex: 1}} />
    <div
      style={{
        alignSelf: 'center',
        width: 300,
        height: 64,
        borderRadius: 32,
        backgroundColor: colours.white,
        boxShadow: '0 12px 28px rgba(23,26,31,0.1)',
        display: 'flex',
        justifyContent: 'space-around',
        alignItems: 'center',
        fontFamily: sans,
        fontSize: 12,
        fontWeight: 750,
        color: colours.muted,
      }}
    >
      <span style={{color: colours.ink}}>Library</span>
      <span>Capture</span>
      <span>Settings</span>
    </div>
  </div>
);

const ScreenCover: React.FC<FeedCoverProps> = ({
  hook,
  kicker,
  title,
  label,
  field,
  accent,
  screen,
  book,
  showBrand = false,
}) => (
  <AbsoluteFill>
    <Field field={field} accent={accent} />
    <div
      style={{
        position: 'absolute',
        width: 1500,
        height: 1500,
        right: -730,
        top: 120,
        borderRadius: '50%',
        border: '1px solid rgba(243,235,221,0.06)',
        boxShadow:
          '0 0 0 120px rgba(243,235,221,0.016), 0 0 0 260px rgba(243,235,221,0.01), 0 0 0 410px rgba(243,235,221,0.006)',
      }}
    />
    {showBrand ? (
      <div
        style={{
          position: 'absolute',
          top: 70,
          left: 72,
          display: 'flex',
          alignItems: 'center',
          gap: 16,
          zIndex: 8,
        }}
      >
        <Img
          src={staticFile('assets/app-icon.png')}
          style={{width: 58, height: 58, borderRadius: 13}}
        />
        <span style={{fontFamily: sans, fontSize: 28, fontWeight: 760, color: coverBone}}>
          BookQuotes
        </span>
      </div>
    ) : null}
    <div
      style={{
        position: 'absolute',
        left: 72,
        top: 245,
        width: 470,
        zIndex: 10,
      }}
    >
      {label ? (
        <div
          style={{
            fontFamily: sans,
            fontSize: 23,
            fontWeight: 760,
            letterSpacing: 2.4,
            textTransform: 'uppercase',
            color: accent,
            marginBottom: 28,
          }}
        >
          {label}
        </div>
      ) : null}
      <div
        style={{
          fontFamily: serif,
          fontSize: hook.length <= 18 ? 86 : 68,
          lineHeight: 1.01,
          fontWeight: 700,
          color: coverBone,
        }}
      >
        {hook}
      </div>
      {title ? (
        <div
          style={{
            marginTop: 28,
            fontFamily: serif,
            fontSize: 36,
            lineHeight: 1.15,
            fontWeight: 650,
            color: `${coverBone}CC`,
          }}
        >
          {title}
        </div>
      ) : null}
      {kicker ? (
        <div
          style={{
            marginTop: 34,
            fontFamily: sans,
            fontSize: 30,
            lineHeight: 1.35,
            fontWeight: 650,
            color: `${coverBone}B8`,
          }}
        >
          {kicker}
        </div>
      ) : null}
    </div>
    <div
      style={{
        position: 'absolute',
        right: 50,
        bottom: 215,
        transform: 'rotate(1.4deg)',
      }}
    >
      <PhoneFrame screen={screen} accent={accent}>
        {book ? <BookOverviewScreen book={book} /> : undefined}
      </PhoneFrame>
    </div>
  </AbsoluteFill>
);

export const BookOverviewHook: React.FC<FeedCoverProps> = (props) => (
  <ScreenCover {...props} />
);

export const FeedCover: React.FC<FeedCoverProps> = (props) => {
  if (props.screen || props.book) {
    return <ScreenCover {...props} />;
  }

  const {hook, kicker, title, label, field, accent, object, jacket, pair, showBrand = false} =
    props;

  return (
  <AbsoluteFill>
    <Field field={field} accent={accent} />
    <div
      style={{
        position: 'absolute',
        left: 88,
        right: 88,
        top: 460,
        bottom: 420,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        textAlign: 'center',
      }}
    >
      {label ? (
        <div
          style={{
            fontFamily: sans,
            fontSize: 24,
            fontWeight: 800,
            letterSpacing: 1.2,
            textTransform: 'uppercase',
            color: accent,
            marginBottom: 28,
          }}
        >
          {label}
        </div>
      ) : null}
      <div
        style={{
          fontFamily: serif,
          fontSize: hookSize(hook),
          lineHeight: 0.98,
          fontWeight: 700,
          color: coverBone,
          maxWidth: 900,
        }}
      >
        {hook}
      </div>
      {title ? (
        <div
          style={{
            marginTop: 28,
            fontFamily: serif,
            fontSize: 42,
            lineHeight: 1.1,
            fontWeight: 650,
            color: `${coverBone}CC`,
          }}
        >
          {title}
        </div>
      ) : null}
      {kicker ? (
        <div
          style={{
            marginTop: 32,
            padding: '16px 24px',
            borderRadius: 8,
            backgroundColor: `${accent}24`,
            border: `1px solid ${accent}66`,
            color: accent,
            fontFamily: sans,
            fontSize: 28,
            fontWeight: 750,
          }}
        >
          {kicker}
        </div>
      ) : null}
      <div style={{marginTop: 54}}>
        <CoverObject object={object} accent={accent} jacket={jacket} pair={pair} />
      </div>
      {showBrand ? (
        <div
          style={{
            marginTop: 40,
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            opacity: 0.82,
          }}
        >
          <Img
            src={staticFile('assets/app-icon.png')}
            style={{width: 42, height: 42, borderRadius: 10}}
          />
          <span style={{fontFamily: sans, fontSize: 22, fontWeight: 750, color: coverBone}}>
            BookQuotes
          </span>
        </div>
      ) : null}
    </div>
  </AbsoluteFill>
  );
};

export const feedCovers: FeedCoverEntry[] = [
  {
    id: 'OneLinePerBook-Cover',
    output: 'out/community/one-line-per-book-cover.png',
    props: {
      hook: 'Keep one line',
      kicker: 'from every book',
      label: 'Summer reading',
      field: 'ink',
      accent: colours.rust,
      object: 'page',
    },
  },
  {
    id: 'AnnotationDebate-Cover',
    output: 'out/community/annotation-debate-cover.png',
    props: {
      hook: 'How do you mark?',
      kicker: 'Underline, tabs, or none',
      label: 'Reader debate',
      field: 'navy',
      accent: colours.gold,
      object: 'marks',
    },
  },
  {
    id: 'CommonplaceRitual-Cover',
    output: 'out/community/commonplace-ritual-cover.png',
    props: {
      hook: 'Not homework',
      kicker: 'A ten-minute ritual',
      label: 'Reading journal',
      field: 'green',
      accent: colours.gold,
      object: 'journal',
    },
  },
  {
    id: 'FindTheLine-Cover',
    output: 'out/community/find-the-line-cover.png',
    props: {
      hook: 'You remember the line',
      kicker: 'Not the book. Not the page.',
      label: 'Reading memory',
      field: 'rust',
      accent: colours.gold,
      object: 'fragment',
    },
  },
  {
    id: 'BookQuotesMarkedPage-Cover',
    output: 'out/bookquotes-marked-page-cover.png',
    props: {
      hook: 'Still losing the lines?',
      kicker: 'Put them somewhere you can find',
      label: 'Marked pages',
      field: 'ink',
      accent: colours.rust,
      object: 'page',
      showBrand: true,
    },
  },
  {
    id: 'BookQuotesIntro-Cover',
    output: 'out/bookquotes-intro-cover.png',
    props: {
      hook: 'Keep the lines',
      kicker: 'Photograph. Review. Find them.',
      label: 'What BookQuotes does',
      field: 'ink',
      accent: colours.gold,
      object: 'page',
      screen: 'screens/appstore/iphone/01_library_grid.png',
      showBrand: true,
    },
  },
  {
    id: 'PresidentialBooksReel-Cover',
    output: 'out/community/presidential-books/reel-cover.png',
    props: {
      hook: '5 biographies',
      kicker: 'worth the commitment',
      title: 'Lincoln, Johnson, Washington, Grant, Truman',
      label: 'Reading list',
      field: 'rust',
      accent: colours.gold,
      object: 'jacket',
      jacket: 'assets/presidential-covers/team-of-rivals.jpg',
      book: {
        title: 'Team of Rivals',
        author: 'Doris Kearns Goodwin',
        jacket: 'assets/presidential-covers/team-of-rivals.jpg',
        status: 'Reader pick',
        collection: 'Presidential biographies',
        note: "Lincoln's political intelligence, and the rivals he brought into cabinet.",
      },
    },
  },
  {
    id: 'HandwrittenBookReview-Cover',
    output: 'out/community/handwritten-team-of-rivals-cover.png',
    props: {
      hook: 'Should you read it?',
      title: 'Team of Rivals',
      kicker: 'Doris Kearns Goodwin',
      label: 'Reading note',
      field: 'rust',
      accent: colours.gold,
      object: 'jacket',
      jacket: 'assets/presidential-covers/team-of-rivals.jpg',
      book: {
        title: 'Team of Rivals',
        author: 'Doris Kearns Goodwin',
        jacket: 'assets/presidential-covers/team-of-rivals.jpg',
        status: 'Finished',
        collection: 'Reading note',
        note: "Lincoln's political intelligence — why this one earns the time.",
      },
    },
  },
  {
    id: 'PresidentialBook-PathToPower-Cover',
    output: 'out/community/presidential-books/path-to-power-cover.png',
    props: {
      hook: 'Start with power',
      title: 'The Path to Power',
      kicker: 'Robert A. Caro',
      label: 'Lyndon Johnson',
      field: 'rust',
      accent: '#C0923F',
      object: 'jacket',
      jacket: 'assets/presidential-covers/path-to-power.jpg',
      book: {
        title: 'The Path to Power',
        author: 'Robert A. Caro',
        jacket: 'assets/presidential-covers/path-to-power.jpg',
        status: 'The true commitment',
        collection: 'Presidential biographies',
        note: 'How political power is actually built. Begin with the Hill Country.',
      },
    },
  },
  {
    id: 'PresidentialBook-Washington-Cover',
    output: 'out/community/presidential-books/washington-cover.png',
    props: {
      hook: 'Behind the monument',
      title: 'Washington: A Life',
      kicker: 'Ron Chernow',
      label: 'George Washington',
      field: 'navy',
      accent: '#54768A',
      object: 'jacket',
      jacket: 'assets/presidential-covers/washington.jpg',
      book: {
        title: 'Washington: A Life',
        author: 'Ron Chernow',
        jacket: 'assets/presidential-covers/washington.jpg',
        status: 'One-volume life',
        collection: 'Presidential biographies',
        note: 'The person behind the monument. A clear all-life entry point.',
      },
    },
  },
  {
    id: 'PresidentialBook-Grant-Cover',
    output: 'out/community/presidential-books/grant-cover.png',
    props: {
      hook: 'Past Appomattox',
      title: 'Grant',
      kicker: 'Ron Chernow',
      label: 'Ulysses S. Grant',
      field: 'green',
      accent: '#5D7A61',
      object: 'jacket',
      jacket: 'assets/presidential-covers/grant.jpg',
      book: {
        title: 'Grant',
        author: 'Ron Chernow',
        jacket: 'assets/presidential-covers/grant.jpg',
        status: 'Reader pick',
        collection: 'Presidential biographies',
        note: 'Reinvention, war and Reconstruction — if your image stops at Appomattox.',
      },
    },
  },
  {
    id: 'PresidentialBook-Truman-Cover',
    output: 'out/community/presidential-books/truman-cover.png',
    props: {
      hook: 'Ordinary, then history',
      title: 'Truman',
      kicker: 'David McCullough',
      label: 'Harry S. Truman',
      field: 'wine',
      accent: '#8D5C65',
      object: 'jacket',
      jacket: 'assets/presidential-covers/truman.jpg',
      book: {
        title: 'Truman',
        author: 'David McCullough',
        jacket: 'assets/presidential-covers/truman.jpg',
        status: 'Narrative history',
        collection: 'Presidential biographies',
        note: 'An ordinary background meeting enormous decisions.',
      },
    },
  },
  {
    id: 'SciFi-01-PlayerOfGames-Cover',
    output: 'out/community/scifi/01-player-of-games-cover.png',
    props: {
      hook: 'Start here',
      title: 'The Player of Games',
      kicker: 'The Culture, without a primer',
      label: 'Reading route',
      field: 'wine',
      accent: '#B75A44',
      object: 'jacket',
      jacket: 'assets/scifi-covers/the-player-of-games.jpg',
      book: {
        title: 'The Player of Games',
        author: 'Iain M. Banks',
        jacket: 'assets/scifi-covers/the-player-of-games.jpg',
        status: 'Start here',
        collection: 'The Culture',
        note: 'A star player enters a society where a game decides who rules.',
      },
    },
  },
  {
    id: 'SciFi-02-CultureRoutes-Cover',
    output: 'out/community/scifi/02-culture-routes-cover.png',
    props: {
      hook: 'No single route',
      kicker: 'Pick the question first',
      label: 'The Culture',
      field: 'green',
      accent: colours.gold,
      object: 'page',
    },
  },
  {
    id: 'SciFi-03-IdeasThroughAGame-Cover',
    output: 'out/community/scifi/03-ideas-through-a-game-cover.png',
    props: {
      hook: 'Ideas as a game',
      title: 'The Player of Games',
      kicker: 'If you want systems first',
      label: 'Reader fit',
      field: 'rust',
      accent: colours.gold,
      object: 'jacket',
      jacket: 'assets/scifi-covers/the-player-of-games.jpg',
      book: {
        title: 'The Player of Games',
        author: 'Iain M. Banks',
        jacket: 'assets/scifi-covers/the-player-of-games.jpg',
        status: 'Systems first',
        collection: 'Reader fit',
        note: 'Big ideas disguised as a game of power and strategy.',
      },
    },
  },
  {
    id: 'SciFi-04-CultureOrder-Cover',
    output: 'out/community/scifi/04-culture-order-cover.png',
    props: {
      hook: 'Which order?',
      kicker: 'Publication, or the book that pulls you',
      label: 'The Culture',
      field: 'navy',
      accent: colours.gold,
      object: 'page',
    },
  },
  {
    id: 'SciFi-05-TwoBigSystems-Cover',
    output: 'out/community/scifi/05-two-big-systems-cover.png',
    props: {
      hook: 'Culture or Three-Body?',
      kicker: 'Two systems. Two ways in.',
      label: 'Reader pairing',
      field: 'wine',
      accent: colours.gold,
      object: 'pair',
      pair: ['The Culture', 'Three-Body'],
    },
  },
  {
    id: 'SciFi-06-ThreeBodyFit-Cover',
    output: 'out/community/scifi/06-three-body-fit-cover.png',
    props: {
      hook: 'Want scale?',
      title: 'The Three-Body Problem',
      kicker: 'Start here if you do',
      label: 'Reader fit',
      field: 'navy',
      accent: '#54768A',
      object: 'page',
    },
  },
  {
    id: 'SciFi-07-ThreeBodyOrder-Cover',
    output: 'out/community/scifi/07-three-body-order-cover.png',
    props: {
      hook: 'Start with one',
      kicker: 'Then read the three in order',
      label: 'Trilogy route',
      field: 'green',
      accent: colours.gold,
      object: 'page',
    },
  },
  {
    id: 'SciFi-08-BigBookPermission-Cover',
    output: 'out/community/scifi/08-big-book-permission-cover.png',
    props: {
      hook: 'Not homework',
      kicker: 'A big book can be slow',
      label: 'Reader note',
      field: 'rust',
      accent: colours.gold,
      object: 'journal',
    },
  },
  {
    id: 'SciFi-09-WhatDoYouWantFirst-Cover',
    output: 'out/community/scifi/09-reader-preferences-cover.png',
    props: {
      hook: 'What first?',
      kicker: 'Idea, world, character, sentence',
      label: 'Reader question',
      field: 'ink',
      accent: colours.gold,
      object: 'marks',
    },
  },
  {
    id: 'SciFi-10-KeepTheLine-Cover',
    output: 'out/community/scifi/10-keep-the-line-cover.png',
    props: {
      hook: 'Keep the line',
      kicker: 'The one that made the idea land',
      label: 'Reading memory',
      field: 'green',
      accent: colours.gold,
      object: 'page',
      showBrand: true,
    },
  },
  {
    id: 'CategoryReel-01-Cover',
    output: 'out/community/category-reels/01-player-of-games-cover.png',
    props: {
      hook: 'Start with the game',
      kicker: 'Iain M. Banks',
      label: 'Science fiction',
      field: 'wine',
      accent: colours.rust,
      object: 'page',
    },
  },
  {
    id: 'CategoryReel-02-Cover',
    output: 'out/community/category-reels/02-team-of-rivals-cover.png',
    props: {
      hook: 'Cabinet of opponents',
      kicker: 'Doris Kearns Goodwin',
      label: 'History',
      field: 'rust',
      accent: colours.gold,
      object: 'page',
    },
  },
  {
    id: 'CategoryReel-03-Cover',
    output: 'out/community/category-reels/03-foster-cover.png',
    props: {
      hook: 'Short on purpose',
      kicker: 'Claire Keegan',
      label: 'Literary fiction',
      field: 'ink',
      accent: colours.rust,
      object: 'page',
    },
  },
  {
    id: 'CategoryReel-04-Cover',
    output: 'out/community/category-reels/04-tinker-tailor-cover.png',
    props: {
      hook: 'The hunt is inside',
      kicker: 'John le Carré',
      label: 'Spy fiction',
      field: 'navy',
      accent: colours.gold,
      object: 'page',
    },
  },
  {
    id: 'CategoryReel-05-Cover',
    output: 'out/community/category-reels/05-four-thousand-weeks-cover.png',
    props: {
      hook: 'Stop clearing the list',
      kicker: 'Oliver Burkeman',
      label: 'Ideas',
      field: 'green',
      accent: colours.gold,
      object: 'page',
    },
  },
  {
    id: 'CategoryReel-06-Cover',
    output: 'out/community/category-reels/06-stoner-cover.png',
    props: {
      hook: 'An ordinary life',
      kicker: 'John Williams',
      label: 'Backlist',
      field: 'wine',
      accent: colours.gold,
      object: 'page',
    },
  },
  {
    id: 'CategoryReel-07-Cover',
    output: 'out/community/category-reels/07-two-front-doors-cover.png',
    props: {
      hook: 'Pick the door',
      kicker: 'Two huge systems',
      label: 'Pairing',
      field: 'green',
      accent: colours.gold,
      object: 'pair',
      pair: ['Player of Games', 'Three-Body'],
    },
  },
];
