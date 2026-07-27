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
import {colours, sans, serif} from './theme';

export type CommunityReelBeat = {
  label: string;
  title: string;
  body: string;
  accent: string;
  screen?: string;
};

export type CommunityReelProps = {
  hook: string;
  intro: string;
  beats: [CommunityReelBeat, CommunityReelBeat, CommunityReelBeat];
  endTitle: string;
  endBody: string;
};

const Frame: React.FC<{accent: string; children: React.ReactNode}> = ({
  accent,
  children,
}) => (
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

const Brand: React.FC = () => (
  <div
    style={{
      position: 'absolute',
      top: 72,
      left: 82,
      display: 'flex',
      alignItems: 'center',
      gap: 17,
      zIndex: 5,
    }}
  >
    <Img
      src={staticFile('assets/app-icon.png')}
      style={{width: 62, height: 62, borderRadius: 14}}
    />
    <span style={{fontFamily: serif, fontSize: 39, fontWeight: 700, color: colours.ink}}>
      BookQuotes
    </span>
  </div>
);

const SceneFooter: React.FC<{text: string}> = ({text}) => (
  <div
    style={{
      position: 'absolute',
      left: 82,
      right: 76,
      bottom: 82,
      fontFamily: sans,
      fontSize: 24,
      fontWeight: 700,
      color: colours.muted,
      display: 'flex',
      justifyContent: 'space-between',
    }}
  >
    <span>{text}</span>
    <span>For readers of paper books</span>
  </div>
);

const Hook: React.FC<Pick<CommunityReelProps, 'hook' | 'intro'>> = ({hook, intro}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 18, stiffness: 95}});

  return (
    <Frame accent={colours.rust}>
      <Brand />
      <div
        style={{
          position: 'absolute',
          left: 82,
          right: 86,
          top: 355,
          transform: `translateY(${interpolate(entrance, [0, 1], [80, 0])}px)`,
        }}
      >
        <div
          style={{
            fontFamily: serif,
            fontSize: 112,
            lineHeight: 1.01,
            fontWeight: 700,
            color: colours.ink,
          }}
        >
          {hook}
        </div>
        <div
          style={{
            marginTop: 62,
            maxWidth: 820,
            paddingLeft: 30,
            borderLeft: `8px solid ${colours.rust}`,
            fontFamily: sans,
            fontSize: 34,
            lineHeight: 1.4,
            fontWeight: 680,
            color: colours.navy,
          }}
        >
          {intro}
        </div>
      </div>
      <SceneFooter text="A question for readers" />
    </Frame>
  );
};

const Beat: React.FC<{beat: CommunityReelBeat; number: number}> = ({beat, number}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 20, stiffness: 90}});
  const hasScreen = Boolean(beat.screen);

  return (
    <Frame accent={beat.accent}>
      <Brand />
      <div
        style={{
          position: 'absolute',
          left: 82,
          right: hasScreen ? 560 : 90,
          top: 290,
          zIndex: 3,
          transform: `translateX(${interpolate(entrance, [0, 1], [-65, 0])}px)`,
        }}
      >
        <div
          style={{
            fontFamily: sans,
            fontSize: 23,
            fontWeight: 800,
            color: beat.accent,
            textTransform: 'uppercase',
          }}
        >
          {String(number).padStart(2, '0')} · {beat.label}
        </div>
        <div
          style={{
            marginTop: 28,
            fontFamily: serif,
            fontSize: hasScreen ? 72 : 99,
            lineHeight: 1.03,
            fontWeight: 700,
            color: colours.ink,
          }}
        >
          {beat.title}
        </div>
        <div
          style={{
            marginTop: 36,
            fontFamily: sans,
            fontSize: hasScreen ? 30 : 37,
            lineHeight: 1.42,
            color: colours.muted,
          }}
        >
          {beat.body}
        </div>
      </div>
      {beat.screen ? (
        <div
          style={{
            position: 'absolute',
            width: 450,
            height: 980,
            right: 62,
            bottom: 210,
            padding: 9,
            borderRadius: 58,
            backgroundColor: colours.ink,
            border: `3px solid ${beat.accent}`,
            overflow: 'hidden',
            transform: `translateY(${interpolate(entrance, [0, 1], [160, 0])}px) rotate(1deg)`,
            boxShadow: '0 38px 80px rgba(23,26,31,0.22)',
          }}
        >
          <Img
            src={staticFile(beat.screen)}
            style={{width: '100%', height: '100%', objectFit: 'cover', borderRadius: 48}}
          />
        </div>
      ) : (
        <div
          style={{
            position: 'absolute',
            left: 82,
            bottom: 310,
            width: 520,
            height: 12,
            backgroundColor: beat.accent,
          }}
        />
      )}
      <SceneFooter text={beat.label} />
    </Frame>
  );
};

const End: React.FC<Pick<CommunityReelProps, 'endTitle' | 'endBody'>> = ({
  endTitle,
  endBody,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 18, stiffness: 100}});

  return (
    <Frame accent={colours.gold}>
      <div
        style={{
          position: 'absolute',
          inset: '210px 80px 170px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          transform: `scale(${interpolate(entrance, [0, 1], [0.9, 1])})`,
        }}
      >
        <Img
          src={staticFile('assets/app-icon.png')}
          style={{
            width: 174,
            height: 174,
            borderRadius: 39,
            boxShadow: '0 26px 60px rgba(45,71,95,0.23)',
          }}
        />
        <div
          style={{
            marginTop: 54,
            fontFamily: serif,
            fontSize: 92,
            lineHeight: 1.03,
            fontWeight: 700,
            color: colours.ink,
          }}
        >
          {endTitle}
        </div>
        <div
          style={{
            marginTop: 34,
            maxWidth: 790,
            fontFamily: sans,
            fontSize: 32,
            lineHeight: 1.42,
            color: colours.muted,
          }}
        >
          {endBody}
        </div>
        <div
          style={{
            marginTop: 48,
            padding: '22px 34px',
            borderRadius: 8,
            backgroundColor: colours.navy,
            fontFamily: sans,
            fontSize: 29,
            fontWeight: 800,
            color: colours.white,
          }}
        >
          BookQuotes · iPhone and iPad
        </div>
      </div>
      <SceneFooter text="Keep the lines that mattered" />
    </Frame>
  );
};

export const CommunityReel: React.FC<CommunityReelProps> = (props) => (
  <AbsoluteFill>
    <Sequence from={0} durationInFrames={96}>
      <Hook hook={props.hook} intro={props.intro} />
    </Sequence>
    <Sequence from={84} durationInFrames={156}>
      <Beat beat={props.beats[0]} number={1} />
    </Sequence>
    <Sequence from={228} durationInFrames={156}>
      <Beat beat={props.beats[1]} number={2} />
    </Sequence>
    <Sequence from={372} durationInFrames={156}>
      <Beat beat={props.beats[2]} number={3} />
    </Sequence>
    <Sequence from={516} durationInFrames={144}>
      <End endTitle={props.endTitle} endBody={props.endBody} />
    </Sequence>
  </AbsoluteFill>
);
