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
import {PhoneFrame} from './FeedCover';
import {colours, coverBone, coverFields, sans, serif} from './theme';

type IntroBeat = {
  step: string;
  title: string;
  body: string;
  screen: string;
  accent: string;
};

const beats: [IntroBeat, IntroBeat, IntroBeat, IntroBeat] = [
  {
    step: '01  Capture',
    title: 'Photograph the marked page.',
    body: 'Underline, highlight or a margin note. BookQuotes works from the page in front of you.',
    screen: 'screens/appstore/iphone/06_captured_page.png',
    accent: colours.rust,
  },
  {
    step: '02  Review',
    title: 'Check the words first.',
    body: 'See the extracted passage, then correct the text, page or note before anything is saved.',
    screen: 'screens/appstore/iphone/07_extraction_review.png',
    accent: colours.gold,
  },
  {
    step: '03  Keep',
    title: 'Save it with the book.',
    body: 'Title, author and page stay with the line. Scan the ISBN or add the book yourself.',
    screen: 'screens/appstore/iphone/02_book_detail.png',
    accent: colours.green,
  },
  {
    step: '04  Find',
    title: 'Search when it returns.',
    body: 'Look across your own library. Tags, collections and export are there when you need them.',
    screen: 'screens/appstore/iphone/04_search_results.png',
    accent: '#8FB4C9',
  },
];

const Field: React.FC<{children: React.ReactNode}> = ({children}) => (
  <AbsoluteFill style={{backgroundColor: coverFields.ink}}>
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background:
          'radial-gradient(circle at 50% 28%, rgba(216,162,103,0.16) 0%, transparent 42%)',
      }}
    />
    <div
      style={{
        position: 'absolute',
        inset: 28,
        border: `1px solid ${coverBone}18`,
      }}
    />
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
    {children}
  </AbsoluteFill>
);

const Brand: React.FC = () => (
  <div
    style={{
      position: 'absolute',
      top: 72,
      left: 78,
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
);

const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 16, stiffness: 110}});
  const opacity = interpolate(frame, [0, 8, 78, 90], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <Field>
      <AbsoluteFill style={{opacity}}>
        <Brand />
        <div
          style={{
            position: 'absolute',
            left: 72,
            top: 245,
            width: 470,
            zIndex: 10,
            transform: `translateY(${interpolate(entrance, [0, 1], [70, 0])}px)`,
          }}
        >
          <div
            style={{
              fontFamily: sans,
              fontSize: 23,
              fontWeight: 780,
              letterSpacing: 2.4,
              textTransform: 'uppercase',
              color: colours.gold,
              marginBottom: 28,
            }}
          >
            For paper-book readers
          </div>
          <div
            style={{
              fontFamily: serif,
              fontSize: 78,
              lineHeight: 1.01,
              fontWeight: 700,
              color: coverBone,
            }}
          >
            Keep the lines you underlined.
          </div>
          <div
            style={{
              marginTop: 34,
              fontFamily: sans,
              fontSize: 30,
              lineHeight: 1.35,
              color: `${coverBone}C7`,
            }}
          >
            Photograph a marked page. Review the words. Find them again.
          </div>
        </div>
        <div
          style={{
            position: 'absolute',
            right: 50,
            bottom: 215,
            transform: `translateY(${interpolate(entrance, [0, 1], [140, 0])}px) rotate(1.4deg)`,
          }}
        >
          <PhoneFrame
            screen="screens/appstore/iphone/01_library_grid.png"
            accent={colours.gold}
          />
        </div>
      </AbsoluteFill>
    </Field>
  );
};

const Beat: React.FC<{beat: IntroBeat}> = ({beat}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 18, stiffness: 96}});

  return (
    <Field>
      <Brand />
      <div
        style={{
          position: 'absolute',
          left: 78,
          width: 430,
          top: 280,
          zIndex: 4,
          transform: `translateX(${interpolate(entrance, [0, 1], [-50, 0])}px)`,
        }}
      >
        <div
          style={{
            fontFamily: sans,
            fontSize: 22,
            fontWeight: 800,
            letterSpacing: 1.4,
            textTransform: 'uppercase',
            color: beat.accent,
          }}
        >
          {beat.step}
        </div>
        <div
          style={{
            marginTop: 28,
            fontFamily: serif,
            fontSize: 68,
            lineHeight: 1.02,
            fontWeight: 700,
            color: coverBone,
          }}
        >
          {beat.title}
        </div>
        <div
          style={{
            marginTop: 32,
            fontFamily: sans,
            fontSize: 30,
            lineHeight: 1.4,
            color: `${coverBone}B8`,
          }}
        >
          {beat.body}
        </div>
      </div>
      <div
        style={{
          position: 'absolute',
          width: 468,
          height: 1016,
          right: 58,
          bottom: 168,
          padding: 10,
          borderRadius: 62,
          backgroundColor: '#0B0D10',
          border: `2px solid ${beat.accent}`,
          overflow: 'hidden',
          boxShadow: '0 36px 80px rgba(0,0,0,0.45)',
          transform: `translateY(${interpolate(entrance, [0, 1], [140, 0])}px) rotate(1.2deg)`,
        }}
      >
        <Img
          src={staticFile(beat.screen)}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            objectPosition: 'top',
            borderRadius: 50,
          }}
        />
      </div>
    </Field>
  );
};

const End: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 16, stiffness: 108}});

  return (
    <Field>
      <div
        style={{
          position: 'absolute',
          inset: '200px 80px 160px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          transform: `scale(${interpolate(entrance, [0, 1], [0.92, 1])})`,
        }}
      >
        <Img
          src={staticFile('assets/app-icon.png')}
          style={{
            width: 168,
            height: 168,
            borderRadius: 38,
            boxShadow: '0 28px 70px rgba(0,0,0,0.4)',
          }}
        />
        <div
          style={{
            marginTop: 48,
            fontFamily: serif,
            fontSize: 86,
            lineHeight: 1.02,
            fontWeight: 700,
            color: coverBone,
          }}
        >
          Your books. Your best lines.
        </div>
        <div
          style={{
            marginTop: 32,
            maxWidth: 760,
            fontFamily: sans,
            fontSize: 30,
            lineHeight: 1.4,
            color: `${coverBone}B8`,
          }}
        >
          A personal quote library on iPhone and iPad. Search, tags, collections, and export.
        </div>
        <div
          style={{
            marginTop: 44,
            padding: '22px 34px',
            borderRadius: 8,
            backgroundColor: colours.gold,
            color: coverFields.ink,
            fontFamily: sans,
            fontSize: 28,
            fontWeight: 800,
          }}
        >
          BookQuotes on the App Store
        </div>
      </div>
    </Field>
  );
};

export const ProductIntro: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: coverFields.ink}}>
    <Sequence from={0} durationInFrames={96}>
      <Hook />
    </Sequence>
    <Sequence from={84} durationInFrames={168}>
      <Beat beat={beats[0]} />
    </Sequence>
    <Sequence from={240} durationInFrames={168}>
      <Beat beat={beats[1]} />
    </Sequence>
    <Sequence from={396} durationInFrames={168}>
      <Beat beat={beats[2]} />
    </Sequence>
    <Sequence from={552} durationInFrames={168}>
      <Beat beat={beats[3]} />
    </Sequence>
    <Sequence from={708} durationInFrames={192}>
      <End />
    </Sequence>
  </AbsoluteFill>
);
