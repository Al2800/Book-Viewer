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
import {colours, coverBone, coverFields, sans, serif} from './theme';

type CoverField = keyof typeof coverFields;
type Visual = 'pages' | 'number' | 'pair' | 'files';

export type CategoryReelProps = {
  hook: string;
  title: string;
  titleLines?: [string, string];
  author: string;
  chips: [string, string, string];
  slash: string;
  catchLine: string;
  left: string;
  right: string;
  accent: string;
  field: CoverField;
  visual: Visual;
  number?: string;
  pair?: [string, string];
  jacket?: string;
};

export type CategoryReelEntry = {
  id: string;
  output: string;
  coverId: string;
  coverOutput: string;
  props: CategoryReelProps;
};

export const CATEGORY_REEL_FRAMES = 300;

const HOOK = 28;
const BOOK = 64;
const CHIPS = 136;
const SLASH = 184;
const END = CATEGORY_REEL_FRAMES;

const Field: React.FC<{
  field: CoverField;
  accent: string;
  children: React.ReactNode;
}> = ({field, accent, children}) => (
  <AbsoluteFill style={{backgroundColor: coverFields[field]}}>
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: `radial-gradient(circle at 50% 38%, ${accent}2E 0%, transparent 48%)`,
      }}
    />
    <div
      style={{
        position: 'absolute',
        inset: 28,
        border: `1px solid ${coverBone}18`,
      }}
    />
    {children}
  </AbsoluteFill>
);

const PageCard: React.FC<{
  width: number;
  height: number;
  rotate: number;
  accent: string;
  underline?: number;
  tabs?: number;
}> = ({width, height, rotate, accent, underline = 0, tabs = 0}) => (
  <div
    style={{
      position: 'relative',
      width,
      height,
      backgroundColor: colours.paper,
      borderRadius: 6,
      boxShadow: '0 28px 64px rgba(0,0,0,0.46)',
      transform: `rotate(${rotate}deg)`,
      padding: '36px 30px 28px',
      overflow: 'hidden',
    }}
  >
    {[0, 1, 2, 3, 4].map((index) => (
      <div
        key={index}
        style={{
          height: 8,
          marginBottom: 20,
          width: index === 4 ? '54%' : `${90 - index * 5}%`,
          backgroundColor: '#D3CBBA',
        }}
      />
    ))}
    <div
      style={{
        marginTop: -6,
        height: 10,
        width: `${72 * underline}%`,
        backgroundColor: accent,
        borderRadius: 99,
      }}
    />
    {tabs > 0
      ? Array.from({length: tabs}).map((_, index) => (
          <div
            key={`tab-${index}`}
            style={{
              position: 'absolute',
              right: -2,
              top: 70 + index * 58,
              width: 18,
              height: 40,
              backgroundColor: index === 0 ? accent : colours.navy,
              borderRadius: '4px 0 0 4px',
              opacity: 1 - index * 0.18,
            }}
          />
        ))
      : null}
  </div>
);

const PairCards: React.FC<{pair: [string, string]; accent: string; lift?: number}> = ({
  pair,
  accent,
  lift = 0,
}) => (
  <div style={{display: 'flex', gap: 28, transform: `translateY(${lift}px)`}}>
    {pair.map((item, index) => (
      <div
        key={item}
        style={{
          width: 300,
          height: 240,
          backgroundColor: index === 0 ? '#1E2A24' : '#2A2228',
          border: `2px solid ${accent}88`,
          borderRadius: 10,
          padding: '32px 26px',
          transform: `rotate(${index === 0 ? -6 : 6}deg)`,
          boxShadow: '0 22px 48px rgba(0,0,0,0.4)',
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
          {index === 0 ? 'Door one' : 'Door two'}
        </div>
        <div
          style={{
            marginTop: 18,
            fontFamily: serif,
            fontSize: 40,
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

const HookScene: React.FC<
  Pick<CategoryReelProps, 'hook' | 'accent' | 'field' | 'visual' | 'number' | 'pair'>
> = ({hook, accent, field, visual, number, pair}) => {
  const frame = useCurrentFrame();
  const underline = interpolate(frame, [4, 22], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <Field field={field} accent={accent}>
      <div
        style={{
          position: 'absolute',
          left: 64,
          right: 64,
          top: 360,
          bottom: 220,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          gap: 54,
        }}
      >
        <div>
          {visual === 'number' && number ? (
            <div
              style={{
                fontFamily: serif,
                fontSize: 240,
                lineHeight: 0.84,
                fontWeight: 700,
                color: coverBone,
              }}
            >
              {number}
            </div>
          ) : (
            <div
              style={{
                fontFamily: serif,
                fontSize: hook.length <= 12 ? 128 : hook.length <= 18 ? 104 : 90,
                lineHeight: 0.96,
                fontWeight: 700,
                color: coverBone,
              }}
            >
              {hook}
            </div>
          )}
          {visual === 'number' ? (
            <div
              style={{
                marginTop: 16,
                fontFamily: serif,
                fontSize: 68,
                fontWeight: 700,
                color: coverBone,
              }}
            >
              {hook}
            </div>
          ) : null}
          <div
            style={{
              margin: '26px auto 0',
              height: 12,
              width: 460,
              transform: `scaleX(${underline})`,
              transformOrigin: 'center',
              backgroundColor: accent,
              borderRadius: 99,
            }}
          />
        </div>
        {visual === 'pages' ? (
          <div style={{display: 'flex', alignItems: 'flex-end', justifyContent: 'center'}}>
            <div style={{marginRight: -80, marginBottom: 40}}>
              <PageCard width={250} height={330} rotate={-12} accent={accent} />
            </div>
            <PageCard width={360} height={470} rotate={-2} accent={accent} underline={underline} />
            <div style={{marginLeft: -90, marginBottom: 28}}>
              <PageCard width={250} height={330} rotate={9} accent={colours.navy} />
            </div>
          </div>
        ) : null}
        {visual === 'files' ? (
          <div style={{display: 'flex', gap: 20, alignItems: 'flex-end'}}>
            <PageCard width={230} height={310} rotate={-8} accent={accent} tabs={2} />
            <PageCard width={260} height={360} rotate={2} accent={accent} tabs={3} underline={underline} />
            <PageCard width={230} height={310} rotate={8} accent={colours.gold} tabs={2} />
          </div>
        ) : null}
        {visual === 'pair' && pair ? <PairCards pair={pair} accent={accent} /> : null}
      </div>
    </Field>
  );
};

const BookScene: React.FC<
  Pick<CategoryReelProps, 'title' | 'titleLines' | 'author' | 'accent' | 'field' | 'jacket'>
> = ({title, titleLines, author, accent, field, jacket}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame, fps, config: {damping: 16, stiffness: 140}});

  return (
    <Field field={field} accent={accent}>
      <div
        style={{
          position: 'absolute',
          left: 56,
          right: 56,
          top: 420,
          bottom: 360,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          transform: `translateY(${interpolate(enter, [0, 1], [36, 0])}px)`,
        }}
      >
        <div
          style={{
            width: '100%',
            backgroundColor: colours.paper,
            borderRadius: 10,
            padding: jacket ? '72px 56px 72px 340px' : '88px 64px',
            boxShadow: '0 36px 80px rgba(0,0,0,0.5)',
            transform: 'rotate(-1.2deg)',
            position: 'relative',
            minHeight: 520,
          }}
        >
          {jacket ? (
            <div
              style={{
                position: 'absolute',
                left: 40,
                top: 56,
                width: 250,
                height: 380,
                padding: 10,
                backgroundColor: colours.white,
                boxShadow: '0 18px 36px rgba(23,26,31,0.22)',
                transform: 'rotate(-4deg)',
              }}
            >
              <Img
                src={staticFile(jacket)}
                style={{width: '100%', height: '100%', objectFit: 'cover', display: 'block'}}
              />
            </div>
          ) : null}
          <div
            style={{
              fontFamily: serif,
              fontSize: titleLines ? 62 : title.length > 20 ? 76 : 88,
              lineHeight: 1.02,
              fontWeight: 700,
              color: colours.ink,
            }}
          >
            {titleLines ? (
              <>
                {titleLines[0]}
                <br />
                {titleLines[1]}
              </>
            ) : (
              title
            )}
          </div>
          <div
            style={{
              marginTop: 22,
              fontFamily: sans,
              fontSize: 32,
              fontWeight: 750,
              color: colours.navy,
            }}
          >
            {author}
          </div>
          <div
            style={{
              marginTop: 28,
              height: 8,
              width: 220,
              backgroundColor: accent,
              borderRadius: 99,
            }}
          />
        </div>
      </div>
    </Field>
  );
};

const ChipsScene: React.FC<
  Pick<CategoryReelProps, 'chips' | 'accent' | 'field'>
> = ({chips, accent, field}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <Field field={field} accent={accent}>
      <div
        style={{
          position: 'absolute',
          left: 72,
          right: 72,
          top: 300,
          bottom: 280,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          gap: 42,
        }}
      >
        {chips.map((chip, index) => {
          const enter = spring({
            frame: Math.max(0, frame - index * 12),
            fps,
            config: {damping: 15, stiffness: 160},
          });
          return (
            <div
              key={chip}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 28,
                opacity: interpolate(enter, [0, 1], [0.15, 1]),
                transform: `translateX(${interpolate(enter, [0, 1], [80, 0])}px)`,
              }}
            >
              <div
                style={{
                  width: 22,
                  height: 22,
                  borderRadius: 99,
                  backgroundColor: accent,
                  flexShrink: 0,
                }}
              />
              <div
                style={{
                  flex: 1,
                  backgroundColor: colours.paper,
                  borderRadius: 8,
                  padding: '40px 42px',
                  boxShadow: '0 18px 40px rgba(0,0,0,0.32)',
                  transform: `rotate(${index === 1 ? 1.2 : -1.1}deg)`,
                }}
              >
                <div
                  style={{
                    fontFamily: serif,
                    fontSize: 68,
                    lineHeight: 1,
                    fontWeight: 700,
                    color: colours.ink,
                  }}
                >
                  {chip}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </Field>
  );
};

const SlashScene: React.FC<
  Pick<CategoryReelProps, 'slash' | 'catchLine' | 'accent' | 'field'>
> = ({slash, catchLine, accent, field}) => {
  const frame = useCurrentFrame();
  const strike = interpolate(frame, [4, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const catchIn = interpolate(frame, [16, 28], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <Field field={field} accent={accent}>
      <div
        style={{
          position: 'absolute',
          left: 72,
          right: 72,
          top: 0,
          bottom: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
        }}
      >
        <div style={{position: 'relative', display: 'inline-block', maxWidth: 920}}>
          <div
            style={{
              fontFamily: serif,
              fontSize: slash.length > 22 ? 78 : 96,
              lineHeight: 1.05,
              fontWeight: 700,
              color: `${coverBone}CC`,
            }}
          >
            {slash}
          </div>
          <div
            style={{
              position: 'absolute',
              left: -16,
              right: -16,
              top: '48%',
              height: 16,
              backgroundColor: accent,
              transform: `scaleX(${strike}) rotate(-6deg)`,
              transformOrigin: 'center',
              borderRadius: 99,
            }}
          />
        </div>
        <div
          style={{
            marginTop: 80,
            fontFamily: serif,
            fontSize: 86,
            lineHeight: 1.02,
            fontWeight: 700,
            color: coverBone,
            opacity: catchIn,
          }}
        >
          {catchLine}
        </div>
      </div>
    </Field>
  );
};

const ChoiceScene: React.FC<
  Pick<CategoryReelProps, 'title' | 'left' | 'right' | 'accent' | 'field'>
> = ({title, left, right, accent, field}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame, fps, config: {damping: 16, stiffness: 130}});

  return (
    <Field field={field} accent={accent}>
      <div
        style={{
          position: 'absolute',
          left: 72,
          right: 72,
          top: 210,
          fontFamily: sans,
          fontSize: 26,
          fontWeight: 800,
          letterSpacing: 1.6,
          textTransform: 'uppercase',
          color: accent,
          textAlign: 'center',
        }}
      >
        {title}
      </div>
      <div
        style={{
          position: 'absolute',
          left: 56,
          right: 56,
          top: 300,
          bottom: 220,
          display: 'flex',
          gap: 28,
          transform: `translateY(${interpolate(enter, [0, 1], [40, 0])}px)`,
        }}
      >
        {[left, right].map((item, index) => (
          <div
            key={item}
            style={{
              flex: 1,
              backgroundColor: index === 0 ? `${accent}22` : '#00000033',
              border: `3px solid ${index === 0 ? accent : `${coverBone}44`}`,
              borderRadius: 16,
              padding: '56px 36px',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'center',
              transform: `rotate(${index === 0 ? -2.5 : 2.5}deg)`,
              boxShadow: '0 28px 60px rgba(0,0,0,0.38)',
            }}
          >
            <div
              style={{
                fontFamily: sans,
                fontSize: 22,
                fontWeight: 800,
                letterSpacing: 1.4,
                textTransform: 'uppercase',
                color: accent,
                marginBottom: 28,
              }}
            >
              {index === 0 ? 'This' : 'Or this'}
            </div>
            <div
              style={{
                fontFamily: serif,
                fontSize: item.length > 16 ? 56 : 68,
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
    </Field>
  );
};

export const CategoryReel: React.FC<CategoryReelProps> = (props) => (
  <AbsoluteFill>
    <Sequence from={0} durationInFrames={HOOK}>
      <HookScene
        hook={props.hook}
        accent={props.accent}
        field={props.field}
        visual={props.visual}
        number={props.number}
        pair={props.pair}
      />
    </Sequence>
    <Sequence from={HOOK} durationInFrames={BOOK - HOOK}>
      <BookScene
        title={props.title}
        titleLines={props.titleLines}
        author={props.author}
        accent={props.accent}
        field={props.field}
        jacket={props.jacket}
      />
    </Sequence>
    <Sequence from={BOOK} durationInFrames={CHIPS - BOOK}>
      <ChipsScene chips={props.chips} accent={props.accent} field={props.field} />
    </Sequence>
    <Sequence from={CHIPS} durationInFrames={SLASH - CHIPS}>
      <SlashScene
        slash={props.slash}
        catchLine={props.catchLine}
        accent={props.accent}
        field={props.field}
      />
    </Sequence>
    <Sequence from={SLASH} durationInFrames={END - SLASH}>
      <ChoiceScene
        title={props.title}
        left={props.left}
        right={props.right}
        accent={props.accent}
        field={props.field}
      />
    </Sequence>
  </AbsoluteFill>
);

export const categoryReels: CategoryReelEntry[] = [
  {
    id: 'CategoryReel-01',
    output: 'out/community/category-reels/01-player-of-games.mp4',
    coverId: 'CategoryReel-01-Cover',
    coverOutput: 'out/community/category-reels/01-player-of-games-cover.png',
    props: {
      hook: 'Skip the primer.',
      title: 'The Player of Games',
      author: 'Iain M. Banks',
      chips: ['One player', 'One game', 'The rule'],
      slash: 'The whole Culture first',
      catchLine: 'Start with this game.',
      left: 'This game',
      right: 'The whole map',
      accent: colours.rust,
      field: 'wine',
      visual: 'pages',
      jacket: 'assets/scifi-covers/the-player-of-games.jpg',
    },
  },
  {
    id: 'CategoryReel-02',
    output: 'out/community/category-reels/02-team-of-rivals.mp4',
    coverId: 'CategoryReel-02-Cover',
    coverOutput: 'out/community/category-reels/02-team-of-rivals-cover.png',
    props: {
      hook: 'Not a shrine.',
      title: 'Team of Rivals',
      author: 'Doris Kearns Goodwin',
      chips: ['Opponents', 'In cabinet', 'A method'],
      slash: 'Weekend Lincoln',
      catchLine: 'It is a long study.',
      left: 'The method',
      right: 'A short life',
      accent: colours.gold,
      field: 'rust',
      visual: 'pages',
      jacket: 'assets/presidential-covers/team-of-rivals.jpg',
    },
  },
  {
    id: 'CategoryReel-03',
    output: 'out/community/category-reels/03-foster.mp4',
    coverId: 'CategoryReel-03-Cover',
    coverOutput: 'out/community/category-reels/03-foster-cover.png',
    props: {
      hook: 'Finish tonight.',
      title: 'Foster',
      author: 'Claire Keegan',
      chips: ['A summer', 'A farm', 'A secret'],
      slash: 'A 400-page novel',
      catchLine: 'Quiet on purpose.',
      left: 'Quiet',
      right: 'Incident',
      accent: colours.rust,
      field: 'ink',
      visual: 'pages',
    },
  },
  {
    id: 'CategoryReel-04',
    output: 'out/community/category-reels/04-tinker-tailor.mp4',
    coverId: 'CategoryReel-04-Cover',
    coverOutput: 'out/community/category-reels/04-tinker-tailor-cover.png',
    props: {
      hook: 'No chase.',
      title: 'Tinker Tailor Soldier Spy',
      author: 'John le Carré',
      chips: ['The office', 'A mole', 'Patience'],
      slash: 'A set-piece every chapter',
      catchLine: 'Give it fifty pages.',
      left: 'Stay',
      right: 'Wait',
      accent: colours.gold,
      field: 'navy',
      visual: 'files',
    },
  },
  {
    id: 'CategoryReel-05',
    output: 'out/community/category-reels/05-four-thousand-weeks.mp4',
    coverId: 'CategoryReel-05-Cover',
    coverOutput: 'out/community/category-reels/05-four-thousand-weeks-cover.png',
    props: {
      hook: 'weeks. That’s all.',
      title: 'Four Thousand Weeks',
      author: 'Oliver Burkeman',
      chips: ['Not a system', 'Not a list', 'A choice'],
      slash: 'Time-management',
      catchLine: 'You have to choose.',
      left: 'Choose',
      right: 'Plan',
      accent: colours.gold,
      field: 'green',
      visual: 'number',
      number: '4,000',
    },
  },
  {
    id: 'CategoryReel-06',
    output: 'out/community/category-reels/06-stoner.mp4',
    coverId: 'CategoryReel-06-Cover',
    coverOutput: 'out/community/category-reels/06-stoner-cover.png',
    props: {
      hook: 'Ordinary.',
      title: 'Stoner',
      author: 'John Williams',
      chips: ['Work', 'A marriage', 'Enough'],
      slash: 'Campus hijinks',
      catchLine: 'Slow, and sad.',
      left: 'Work',
      right: 'Plot',
      accent: colours.gold,
      field: 'wine',
      visual: 'pages',
    },
  },
  {
    id: 'CategoryReel-07',
    output: 'out/community/category-reels/07-two-front-doors.mp4',
    coverId: 'CategoryReel-07-Cover',
    coverOutput: 'out/community/category-reels/07-two-front-doors-cover.png',
    props: {
      hook: 'Two doors.',
      title: 'Two front doors',
      titleLines: ['The Player of Games', 'The Three-Body Problem'],
      author: 'Iain M. Banks / Cixin Liu',
      chips: ['Games and politics', 'Or cosmic mystery', 'Same size, different door'],
      slash: 'A gentle on-ramp',
      catchLine: 'Name the difficulty.',
      left: 'The game',
      right: 'The cosmos',
      accent: colours.gold,
      field: 'green',
      visual: 'pair',
      pair: ['Player of Games', 'Three-Body'],
    },
  },
];
