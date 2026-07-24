import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Easing,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {colours, sans, serif} from './theme';

export type BookQuotesReelProps = {
  hook: string;
  captureTitle: string;
  captureBody: string;
  libraryTitle: string;
  libraryBody: string;
  endTitle: string;
  website: string;
  voiceoverPath: string | null;
};

const Brand: React.FC = () => (
  <div
    style={{
      position: 'absolute',
      left: 70,
      top: 68,
      display: 'flex',
      alignItems: 'center',
      gap: 18,
      zIndex: 20,
    }}
  >
    <Img
      src={staticFile('assets/app-icon.png')}
      style={{width: 66, height: 66, borderRadius: 15}}
    />
    <div style={{fontFamily: serif, fontWeight: 700, fontSize: 42, color: colours.ink}}>
      BookQuotes
    </div>
  </div>
);

const Background: React.FC<{accent: string}> = ({accent}) => (
  <AbsoluteFill style={{backgroundColor: colours.paper}}>
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
        width: 16,
        top: 34,
        bottom: 34,
        right: 34,
        backgroundColor: accent,
      }}
    />
  </AbsoluteFill>
);

const Footer: React.FC<{accent: string; label?: string}> = ({
  accent,
  label = 'Made for readers who mark their books',
}) => (
  <div
    style={{
      position: 'absolute',
      left: 70,
      right: 82,
      bottom: 105,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      fontFamily: sans,
      fontWeight: 650,
      fontSize: 24,
      color: colours.muted,
      zIndex: 20,
    }}
  >
    <span>{label}</span>
    <span style={{color: accent}}>BookQuotes</span>
  </div>
);

const MarkedPage: React.FC<{accent: string}> = ({accent}) => (
  <div
    style={{
      position: 'absolute',
      inset: 28,
      borderRadius: 34,
      backgroundColor: colours.white,
      padding: '130px 48px 54px',
      fontFamily: serif,
      color: colours.ink,
      overflow: 'hidden',
    }}
  >
    <div
      style={{
        position: 'absolute',
        top: 42,
        left: 48,
        fontFamily: sans,
        fontSize: 22,
        fontWeight: 760,
        color: accent,
        textTransform: 'uppercase',
      }}
    >
      Marked page
    </div>
    <div style={{fontSize: 38, lineHeight: 1.68}}>
      A marked passage becomes more useful when it can return to us at the right moment.
    </div>
    <div
      style={{
        height: 8,
        backgroundColor: accent,
        marginTop: -12,
        width: '89%',
        opacity: 0.85,
      }}
    />
    <div
      style={{
        position: 'absolute',
        left: 48,
        right: 48,
        bottom: 65,
        padding: '24px 26px',
        border: `2px solid ${accent}`,
        borderRadius: 8,
        fontFamily: sans,
        color: colours.navy,
        fontSize: 25,
        lineHeight: 1.35,
        fontWeight: 700,
      }}
    >
      Photograph the passage, then review the extracted text before saving.
    </div>
  </div>
);

const HookScene: React.FC<{hook: string}> = ({hook}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 17, stiffness: 105}});
  const opacity = interpolate(frame, [0, 10, 76, 90], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{opacity}}>
      <Background accent={colours.rust} />
      <Brand />
      <div
        style={{
          position: 'absolute',
          left: 75,
          right: 95,
          top: 380,
          fontFamily: serif,
          fontSize: 112,
          lineHeight: 1.02,
          fontWeight: 700,
          color: colours.ink,
          transform: `translateY(${interpolate(entrance, [0, 1], [80, 0])}px)`,
        }}
      >
        {hook}
      </div>
      <div
        style={{
          position: 'absolute',
          left: 75,
          top: 1050,
          borderLeft: `8px solid ${colours.rust}`,
          padding: '16px 0 16px 28px',
          color: colours.navy,
          fontFamily: sans,
          fontSize: 34,
          fontWeight: 720,
        }}
      >
        Put them somewhere you can find.
      </div>
      <Footer accent={colours.rust} />
    </AbsoluteFill>
  );
};

const PhoneScene: React.FC<{
  eyebrow: string;
  title: string;
  body: string;
  screen?: string;
  accent: string;
}> = ({eyebrow, title, body, screen, accent}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const phoneEntrance = spring({frame, fps, config: {damping: 20, stiffness: 92}});
  const textX = interpolate(frame, [0, 22], [-60, 0], {
    easing: Easing.out(Easing.cubic),
    extrapolateRight: 'clamp',
  });
  const opacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <Background accent={accent} />
      <Brand />
      <div
        style={{
          position: 'absolute',
          left: 70,
          top: 250,
          width: 475,
          opacity,
          transform: `translateX(${textX}px)`,
          zIndex: 10,
        }}
      >
        <div
          style={{
            color: accent,
            fontFamily: sans,
            fontWeight: 760,
            fontSize: 24,
            textTransform: 'uppercase',
            marginBottom: 28,
          }}
        >
          {eyebrow}
        </div>
        <div
          style={{
            color: colours.ink,
            fontFamily: serif,
            fontSize: 77,
            lineHeight: 1.03,
            fontWeight: 700,
          }}
        >
          {title}
        </div>
        <div
          style={{
            color: colours.muted,
            fontFamily: sans,
            fontSize: 31,
            lineHeight: 1.4,
            marginTop: 34,
          }}
        >
          {body}
        </div>
      </div>
      <div
        style={{
          position: 'absolute',
          width: 492,
          height: 1070,
          right: 52,
          bottom: 215,
          padding: 10,
          borderRadius: 64,
          backgroundColor: colours.ink,
          border: `3px solid ${accent}`,
          boxShadow: '0 44px 90px rgba(23,26,31,0.24)',
          overflow: 'hidden',
          transform: `translateY(${interpolate(phoneEntrance, [0, 1], [180, 0])}px) rotate(1deg)`,
        }}
      >
        {screen ? (
          <Img
            src={staticFile(screen)}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              borderRadius: 52,
            }}
          />
        ) : (
          <MarkedPage accent={accent} />
        )}
      </div>
      <Footer accent={accent} />
    </AbsoluteFill>
  );
};

const EndScene: React.FC<{title: string; website: string}> = ({title, website}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 17, stiffness: 108}});
  const opacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{opacity}}>
      <Background accent={colours.gold} />
      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '0 90px 170px',
          transform: `scale(${interpolate(entrance, [0, 1], [0.9, 1])})`,
        }}
      >
        <Img
          src={staticFile('assets/app-icon.png')}
          style={{
            width: 190,
            height: 190,
            borderRadius: 42,
            boxShadow: '0 28px 70px rgba(45,71,95,0.25)',
            marginBottom: 58,
          }}
        />
        <div
          style={{
            color: colours.ink,
            fontFamily: serif,
            fontSize: 94,
            lineHeight: 1.04,
            textAlign: 'center',
            fontWeight: 700,
          }}
        >
          {title}
        </div>
        <div
          style={{
            marginTop: 52,
            padding: '24px 38px',
            borderRadius: 8,
            backgroundColor: colours.navy,
            color: colours.white,
            fontFamily: sans,
            fontSize: 32,
            fontWeight: 760,
          }}
        >
          {website}
        </div>
      </div>
      <Footer accent={colours.gold} label="Capture. Review. Remember." />
    </AbsoluteFill>
  );
};

export const BookQuotesReel: React.FC<BookQuotesReelProps> = (props) => (
  <AbsoluteFill style={{backgroundColor: colours.paper}}>
    {props.voiceoverPath ? <Audio src={staticFile(props.voiceoverPath)} /> : null}
    <Sequence from={0} durationInFrames={90}>
      <HookScene hook={props.hook} />
    </Sequence>
    <Sequence from={78} durationInFrames={198}>
      <PhoneScene
        eyebrow="From paper to library"
        title={props.captureTitle}
        body={props.captureBody}
        accent={colours.rust}
      />
    </Sequence>
    <Sequence from={264} durationInFrames={216}>
      <PhoneScene
        eyebrow="Your reading memory"
        title={props.libraryTitle}
        body={props.libraryBody}
        screen="screens/library.png"
        accent={colours.green}
      />
    </Sequence>
    <Sequence from={468} durationInFrames={192}>
      <EndScene title={props.endTitle} website={props.website} />
    </Sequence>
  </AbsoluteFill>
);
