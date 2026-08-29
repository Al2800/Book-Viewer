import React from 'react';
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {BookOverviewHook} from './FeedCover';
import {colours, sans, serif} from './theme';

const hand =
  '"Bradley Hand", "Segoe Print", "Chalkboard SE", cursive';

const sceneOpacity = (frame: number, start: number, end: number) =>
  interpolate(frame, [start, start + 14, end - 14, end], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

const DrawnPath: React.FC<{
  d: string;
  progress: number;
  colour?: string;
  width?: number;
  opacity?: number;
}> = ({
  d,
  progress,
  colour = colours.rust,
  width = 8,
  opacity = 1,
}) => (
  <>
    <path
      d={d}
      pathLength={1}
      fill="none"
      stroke={colour}
      strokeWidth={width}
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeDasharray={1}
      strokeDashoffset={1 - progress}
      opacity={opacity}
    />
    <path
      d={d}
      pathLength={1}
      fill="none"
      stroke={colour}
      strokeWidth={Math.max(2, width * 0.3)}
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeDasharray={1}
      strokeDashoffset={1 - progress}
      opacity={opacity * 0.42}
      transform="translate(2 -2)"
    />
  </>
);

const Paper: React.FC<{children: React.ReactNode}> = ({children}) => (
  <AbsoluteFill
    style={{
      backgroundColor: '#F7F2E8',
      backgroundImage:
        'linear-gradient(rgba(45,71,95,0.055) 1px, transparent 1px), radial-gradient(circle at 18% 14%, rgba(168,92,74,0.07), transparent 28%), radial-gradient(circle at 86% 82%, rgba(74,123,98,0.065), transparent 30%)',
      backgroundSize: '100% 78px, 100% 100%, 100% 100%',
      color: colours.ink,
      overflow: 'hidden',
    }}
  >
    <div
      style={{
        position: 'absolute',
        left: 92,
        top: 0,
        bottom: 0,
        width: 3,
        backgroundColor: 'rgba(168,92,74,0.2)',
      }}
    />
    {children}
  </AbsoluteFill>
);

const SeriesLabel: React.FC<{index?: string}> = ({index = '01'}) => (
  <div
    style={{
      position: 'absolute',
      top: 68,
      left: 132,
      right: 70,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'baseline',
      fontFamily: sans,
      color: colours.navy,
    }}
  >
    <span
      style={{
        fontSize: 24,
        fontWeight: 850,
        textTransform: 'uppercase',
      }}
    >
      Today&apos;s reading note
    </span>
    <span
      style={{
        fontFamily: sans,
        fontSize: 21,
        lineHeight: 1,
        fontWeight: 850,
        textTransform: 'uppercase',
        letterSpacing: 0,
      }}
    >
      {index}
    </span>
  </div>
);

const Cover: React.FC<{
  width: number;
  top: number;
  left: number;
  rotate?: number;
  scale?: number;
}> = ({width, top, left, rotate = -2, scale = 1}) => (
  <div
    style={{
      position: 'absolute',
      top,
      left,
      width,
      height: width * 1.52,
      padding: 8,
      backgroundColor: colours.white,
      boxShadow: '0 28px 54px rgba(23,26,31,0.2)',
      transform: `rotate(${rotate}deg) scale(${scale})`,
      transformOrigin: 'center center',
    }}
  >
    <Img
      src={staticFile('assets/presidential-covers/team-of-rivals.jpg')}
      style={{width: '100%', height: '100%', objectFit: 'contain'}}
    />
  </div>
);

const HookScene: React.FC<{frame: number}> = ({frame}) => (
  <AbsoluteFill style={{opacity: sceneOpacity(frame, 0, 112)}}>
    <BookOverviewHook
      hook="Should you read it?"
      title="Team of Rivals"
      kicker="Doris Kearns Goodwin"
      label="Reading note"
      field="rust"
      accent={colours.gold}
      object="jacket"
      jacket="assets/presidential-covers/team-of-rivals.jpg"
      book={{
        title: 'Team of Rivals',
        author: 'Doris Kearns Goodwin',
        jacket: 'assets/presidential-covers/team-of-rivals.jpg',
        status: 'Finished',
        collection: 'Reading note',
        note: "Lincoln's political intelligence — why this one earns the time.",
      }}
    />
  </AbsoluteFill>
);

const ReadForScene: React.FC<{frame: number}> = ({frame}) => {
  const local = frame - 96;
  const {fps} = useVideoConfig();
  const enter = spring({
    frame: Math.max(0, local),
    fps,
    config: {damping: 18, stiffness: 105},
  });
  const underline = interpolate(local, [28, 72], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });
  const ticks = interpolate(local, [58, 104], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{opacity: sceneOpacity(frame, 96, 232)}}>
      <SeriesLabel index="the idea" />
      <Cover
        width={360}
        top={300}
        left={125}
        rotate={-3}
        scale={interpolate(enter, [0, 1], [0.88, 1])}
      />
      <div
        style={{
          position: 'absolute',
          left: 560,
          right: 76,
          top: 330,
          transform: `translateX(${interpolate(enter, [0, 1], [80, 0])}px)`,
        }}
      >
        <div
          style={{
            fontFamily: hand,
            fontSize: 48,
            fontWeight: 700,
            color: colours.ink,
            transform: 'rotate(-3deg)',
          }}
        >
          What it reveals
        </div>
        <div
          style={{
            marginTop: 48,
            fontFamily: serif,
            fontSize: 76,
            lineHeight: 1.05,
            fontWeight: 700,
          }}
        >
          Leadership through rivalry
        </div>
        <div
          style={{
            marginTop: 52,
            fontFamily: sans,
            fontSize: 32,
            lineHeight: 1.42,
            fontWeight: 600,
            color: colours.navy,
          }}
        >
          Goodwin follows the ambitions, resentments and alliances inside
          Lincoln&apos;s cabinet.
        </div>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 150,
          right: 100,
          top: 1120,
          display: 'grid',
          gridTemplateColumns: '1fr 1fr 1fr',
          gap: 28,
          fontFamily: hand,
          fontSize: 39,
          fontWeight: 700,
          color: colours.green,
          transform: 'rotate(-1deg)',
          opacity: ticks,
        }}
      >
        <span>✓ ambition</span>
        <span>✓ rivalry</span>
        <span>✓ compromise</span>
      </div>
      <svg
        viewBox="0 0 1080 1920"
        style={{position: 'absolute', inset: 0, width: '100%', height: '100%'}}
      >
        <DrawnPath
          d="M 552 668 C 670 652, 817 658, 982 644"
          progress={underline}
          width={10}
        />
      </svg>
    </AbsoluteFill>
  );
};

const HonestNoteScene: React.FC<{frame: number}> = ({frame}) => {
  const local = frame - 216;
  const {fps} = useVideoConfig();
  const enter = spring({
    frame: Math.max(0, local),
    fps,
    config: {damping: 17, stiffness: 95},
  });
  const box = interpolate(local, [20, 68], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const underline = interpolate(local, [54, 96], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{opacity: sceneOpacity(frame, 216, 352)}}>
      <SeriesLabel index="what to expect" />
      <div
        style={{
          position: 'absolute',
          left: 130,
          top: 265,
          width: 795,
          padding: '68px 62px 76px',
          backgroundColor: 'rgba(255,253,248,0.88)',
          boxShadow: '7px 9px 0 rgba(45,71,95,0.12)',
          transform: `rotate(-1.2deg) scale(${interpolate(enter, [0, 1], [0.9, 1])})`,
        }}
      >
        <div
          style={{
            fontFamily: hand,
            fontSize: 52,
            fontWeight: 700,
            color: colours.ink,
          }}
        >
          The approach
        </div>
        <div
          style={{
            marginTop: 58,
            fontFamily: serif,
            fontSize: 88,
            lineHeight: 1.08,
            fontWeight: 700,
          }}
        >
          Lincoln alongside the people around him.
        </div>
        <div
          style={{
            marginTop: 60,
            fontFamily: sans,
            fontSize: 30,
            lineHeight: 1.45,
            color: colours.navy,
          }}
        >
          The book follows several lives and political relationships, not the
          president in isolation.
        </div>
      </div>
      <svg
        viewBox="0 0 1080 1920"
        style={{position: 'absolute', inset: 0, width: '100%', height: '100%'}}
      >
        <DrawnPath
          d="M 112 230 C 300 204, 710 212, 962 242 L 947 1260 C 720 1300, 316 1302, 104 1264 Z"
          progress={box}
          colour={colours.navy}
          width={6}
          opacity={0.62}
        />
        <DrawnPath
          d="M 188 750 C 372 730, 582 735, 826 716"
          progress={underline}
          width={13}
          opacity={0.78}
        />
      </svg>
    </AbsoluteFill>
  );
};

const VerdictScene: React.FC<{frame: number}> = ({frame}) => {
  const local = frame - 336;
  const {fps} = useVideoConfig();
  const enter = spring({
    frame: Math.max(0, local),
    fps,
    config: {damping: 18, stiffness: 96},
  });
  const circle = interpolate(local, [38, 88], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{opacity: sceneOpacity(frame, 336, 450)}}>
      <SeriesLabel index="the verdict" />
      <Cover
        width={330}
        top={280}
        left={375}
        rotate={2}
        scale={interpolate(enter, [0, 1], [0.78, 1])}
      />
      <div
        style={{
          position: 'absolute',
          left: 120,
          right: 90,
          top: 875,
          textAlign: 'center',
          transform: `translateY(${interpolate(enter, [0, 1], [60, 0])}px)`,
        }}
      >
        <div
          style={{
            fontFamily: hand,
            fontSize: 45,
            fontWeight: 700,
            color: colours.ink,
            transform: 'rotate(-2deg)',
          }}
        >
          Our verdict
        </div>
        <div
          style={{
            marginTop: 38,
            fontFamily: serif,
            fontSize: 64,
            lineHeight: 1.08,
            fontWeight: 700,
          }}
        >
          Read it for leadership
          <br />
          told through ambition,
          <br />
          rivalry and compromise.
        </div>
      </div>
      <svg
        viewBox="0 0 1080 1920"
        style={{position: 'absolute', inset: 0, width: '100%', height: '100%'}}
      >
        <DrawnPath
          d="M 178 865 C 340 816, 760 820, 908 886 C 970 914, 970 1238, 904 1282 C 748 1360, 330 1352, 174 1280 C 112 1252, 112 918, 178 865"
          progress={circle}
          colour={colours.green}
          width={8}
          opacity={0.72}
        />
      </svg>
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 145,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          gap: 18,
          opacity: interpolate(local, [64, 92], [0, 1], {
            extrapolateLeft: 'clamp',
            extrapolateRight: 'clamp',
          }),
        }}
      >
        <Img
          src={staticFile('assets/app-icon.png')}
          style={{width: 58, height: 58, borderRadius: 13}}
        />
        <span
          style={{
            fontFamily: serif,
            fontSize: 37,
            fontWeight: 700,
            color: colours.navy,
          }}
        >
          BookQuotes
        </span>
        <span
          style={{
            fontFamily: hand,
            fontSize: 30,
            fontWeight: 700,
            color: colours.muted,
          }}
        >
          remember what you read
        </span>
      </div>
    </AbsoluteFill>
  );
};

export const HandwrittenBookReview: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill>
      <Paper>
        <ReadForScene frame={frame} />
        <HonestNoteScene frame={frame} />
        <VerdictScene frame={frame} />
      </Paper>
      <HookScene frame={frame} />
    </AbsoluteFill>
  );
};
