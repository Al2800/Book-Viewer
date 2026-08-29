import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Img,
  Sequence,
  interpolate,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {colours, coverBone, coverFields, sans, serif} from './theme';

type CoverField = keyof typeof coverFields;

export const ILLUSTRATED_REEL_FRAMES = 540;

type StillName = 'hook' | 'world' | 'mechanism' | 'catch' | 'jacket';

type Beat = {
  still: StillName;
  kicker: string;
  title: string;
  body: string;
  from: number;
  duration: number;
};

const stillSrc = (folder: string, still: StillName) =>
  still === 'jacket' ? `${folder}/jacket.jpg` : `${folder}/${still}.png`;

export type IllustratedReelProps = {
  folder: string;
  accent: string;
  field: CoverField;
  beats: [Beat, Beat, Beat, Beat, Beat];
  musicPath?: string | null;
};

export type IllustratedReelEntry = {
  id: string;
  coverId: string;
  output: string;
  coverOutput: string;
  props: IllustratedReelProps;
};

const Field: React.FC<{field: CoverField; accent: string}> = ({field, accent}) => (
  <AbsoluteFill style={{backgroundColor: coverFields[field]}}>
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: `radial-gradient(circle at 78% 28%, ${accent}28 0%, transparent 38%)`,
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
        border: '1px solid rgba(243,235,221,0.035)',
        boxShadow:
          '0 0 0 120px rgba(243,235,221,0.012), 0 0 0 260px rgba(243,235,221,0.008), 0 0 0 410px rgba(243,235,221,0.005)',
      }}
    />
  </AbsoluteFill>
);

const BeatScene: React.FC<{
  folder: string;
  still: Beat['still'];
  kicker: string;
  title: string;
  body: string;
  accent: string;
  field: CoverField;
}> = ({folder, still, kicker, title, body, accent, field}) => {
  const frame = useCurrentFrame();
  const push = interpolate(frame, [0, 60], [1, 1.06], {
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <Field field={field} accent={accent} />
      <AbsoluteFill
        style={{
          transform: `scale(${push})`,
          transformOrigin: '62% 55%',
        }}
      >
        <Img
          src={staticFile(stillSrc(folder, still))}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            objectPosition: still === 'jacket' ? 'center top' : 'center',
          }}
        />
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          background:
            still === 'jacket'
              ? 'linear-gradient(90deg, rgba(8,10,14,0.82) 0%, rgba(8,10,14,0.42) 46%, rgba(8,10,14,0.22) 100%)'
              : 'linear-gradient(90deg, rgba(8,10,14,0.88) 0%, rgba(8,10,14,0.62) 42%, rgba(8,10,14,0.18) 72%, rgba(8,10,14,0.35) 100%)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 72,
          top: 260,
          width: 560,
          zIndex: 4,
        }}
      >
        <div
          style={{
            display: 'inline-block',
            padding: '14px 22px',
            borderRadius: 24,
            color: accent,
            backgroundColor: `${accent}1A`,
            border: `1px solid ${accent}44`,
            fontFamily: sans,
            fontSize: 22,
            fontWeight: 750,
            letterSpacing: 1.4,
            textTransform: 'uppercase',
          }}
        >
          {kicker}
        </div>
        <div
          style={{
            marginTop: 36,
            fontFamily: serif,
            fontSize: title.length > 42 ? 64 : 76,
            lineHeight: 1.02,
            fontWeight: 700,
            color: coverBone,
            letterSpacing: '-0.03em',
          }}
        >
          {title}
        </div>
        <div
          style={{
            marginTop: 28,
            fontFamily: sans,
            fontSize: 32,
            lineHeight: 1.32,
            fontWeight: 650,
            color: '#C4C0B6',
          }}
        >
          {body}
        </div>
        <div
          style={{
            marginTop: 32,
            height: 8,
            width: 168,
            backgroundColor: accent,
            borderRadius: 99,
          }}
        />
      </div>
    </AbsoluteFill>
  );
};

export const IllustratedReel: React.FC<IllustratedReelProps> = ({
  folder,
  accent,
  field,
  beats,
  musicPath = null,
}) => (
  <AbsoluteFill style={{backgroundColor: '#080a0e'}}>
    {musicPath ? (
      <Audio src={staticFile(musicPath)} volume={0.16} />
    ) : null}
    {beats.map((beat) => (
      <Sequence key={`${beat.from}-${beat.still}`} from={beat.from} durationInFrames={beat.duration}>
        <BeatScene
          folder={folder}
          still={beat.still}
          kicker={beat.kicker}
          title={beat.title}
          body={beat.body}
          accent={accent}
          field={field}
        />
      </Sequence>
    ))}
  </AbsoluteFill>
);

export const IllustratedCover: React.FC<{
  folder: string;
  still?: Beat['still'];
  hook: string;
  kicker: string;
  accent: string;
  field: CoverField;
}> = ({folder, still = 'hook', hook, kicker, accent, field}) => (
  <AbsoluteFill>
    <Field field={field} accent={accent} />
    <Img
      src={staticFile(stillSrc(folder, still))}
      style={{width: '100%', height: '100%', objectFit: 'cover'}}
    />
    <AbsoluteFill
      style={{
        background:
          'linear-gradient(180deg, rgba(8,10,14,0.25) 0%, rgba(8,10,14,0.15) 38%, rgba(8,10,14,0.72) 100%)',
      }}
    />
    <div
      style={{
        position: 'absolute',
        left: 88,
        right: 88,
        top: 520,
        textAlign: 'center',
      }}
    >
      <div
        style={{
          fontFamily: sans,
          fontSize: 24,
          fontWeight: 800,
          letterSpacing: 1.6,
          textTransform: 'uppercase',
          color: accent,
          marginBottom: 22,
        }}
      >
        {kicker}
      </div>
      <div
        style={{
          fontFamily: serif,
          fontSize: hook.length <= 18 ? 96 : 78,
          lineHeight: 0.98,
          fontWeight: 700,
          color: coverBone,
        }}
      >
        {hook}
      </div>
    </div>
  </AbsoluteFill>
);

export const illustratedReels: IllustratedReelEntry[] = [
  {
    id: 'Illustrated-01',
    coverId: 'Illustrated-01-Cover',
    output: 'out/illustrated/01-player-of-games.mp4',
    coverOutput: 'out/illustrated/01-player-of-games-cover.png',
    props: {
      folder: 'illustrated/cr-01',
      accent: colours.rust,
      field: 'wine',
      musicPath: null,
      beats: [
        {from: 0, duration: 60, still: 'hook', kicker: 'Where to start', title: 'Want the Culture without the tour?', body: 'A way in, without a 100-page primer.'},
        {from: 60, duration: 90, still: 'jacket', kicker: 'Science fiction', title: 'The Player of Games', body: 'Iain M. Banks'},
        {from: 150, duration: 120, still: 'mechanism', kicker: 'What happens', title: 'One game decides who rules an empire.', body: 'The game is the argument.'},
        {from: 270, duration: 120, still: 'catch', kicker: 'The catch', title: 'Not for intimate psychology first.', body: 'If character comes first, start elsewhere.'},
        {from: 390, duration: 150, still: 'hook', kicker: 'The reading rule', title: 'Start here for grand design.', body: 'Skip it if you want a character study.'},
      ],
    },
  },
  {
    id: 'Illustrated-02',
    coverId: 'Illustrated-02-Cover',
    output: 'out/illustrated/02-team-of-rivals.mp4',
    coverOutput: 'out/illustrated/02-team-of-rivals-cover.png',
    props: {
      folder: 'illustrated/cr-02',
      accent: colours.gold,
      field: 'rust',
      musicPath: null,
      beats: [
        {from: 0, duration: 60, still: 'hook', kicker: 'History', title: 'Not a greatest-hits Lincoln.', body: 'A cabinet of opponents, not a shrine.'},
        {from: 60, duration: 90, still: 'jacket', kicker: 'Biography', title: 'Team of Rivals', body: 'Doris Kearns Goodwin'},
        {from: 150, duration: 120, still: 'mechanism', kicker: 'What it is', title: 'How Lincoln used the rivals in cabinet.', body: 'A study of a working method.'},
        {from: 270, duration: 120, still: 'catch', kicker: 'The catch', title: 'It is long.', body: 'Not a weekend biography.'},
        {from: 390, duration: 150, still: 'hook', kicker: 'The reading rule', title: 'Read it for the method.', body: 'Skip it if you want a short life.'},
      ],
    },
  },
  {
    id: 'Illustrated-03',
    coverId: 'Illustrated-03-Cover',
    output: 'out/illustrated/03-foster.mp4',
    coverOutput: 'out/illustrated/03-foster-cover.png',
    props: {
      folder: 'illustrated/cr-03',
      accent: colours.rust,
      field: 'ink',
      musicPath: null,
      beats: [
        {from: 0, duration: 60, still: 'hook', kicker: 'Literary fiction', title: 'A short book you can finish tonight.', body: 'And still think about next week.'},
        {from: 60, duration: 90, still: 'world', kicker: 'Novella', title: 'Foster', body: 'Claire Keegan'},
        {from: 150, duration: 120, still: 'mechanism', kicker: 'What happens', title: 'A girl sent to a farm for the summer.', body: 'The house is warm. Then the secret.'},
        {from: 270, duration: 120, still: 'catch', kicker: 'The catch', title: 'Slight on plot.', body: 'Too quiet if you need incident every chapter.'},
        {from: 390, duration: 150, still: 'hook', kicker: 'The reading rule', title: 'Read for precision, not volume.', body: 'Do not come for the film.'},
      ],
    },
  },
  {
    id: 'Illustrated-04',
    coverId: 'Illustrated-04-Cover',
    output: 'out/illustrated/04-tinker-tailor.mp4',
    coverOutput: 'out/illustrated/04-tinker-tailor-cover.png',
    props: {
      folder: 'illustrated/cr-04',
      accent: colours.gold,
      field: 'navy',
      musicPath: null,
      beats: [
        {from: 0, duration: 60, still: 'hook', kicker: 'Spy fiction', title: 'Violence is in the office, not the chase.', body: 'A mole hunt that rewards patience.'},
        {from: 60, duration: 90, still: 'world', kicker: 'The Circus', title: 'Tinker Tailor Soldier Spy', body: 'John le Carré'},
        {from: 150, duration: 120, still: 'mechanism', kicker: 'What happens', title: 'Smiley is brought back to find a traitor.', body: 'The hunt is inside the service.'},
        {from: 270, duration: 120, still: 'catch', kicker: 'The catch', title: 'The first third is dense.', body: 'Give it fifty pages, or wait.'},
        {from: 390, duration: 150, still: 'hook', kicker: 'The reading rule', title: 'For institutional deception.', body: 'Not for set-pieces.'},
      ],
    },
  },
  {
    id: 'Illustrated-05',
    coverId: 'Illustrated-05-Cover',
    output: 'out/illustrated/05-four-thousand-weeks.mp4',
    coverOutput: 'out/illustrated/05-four-thousand-weeks-cover.png',
    props: {
      folder: 'illustrated/cr-05',
      accent: colours.gold,
      field: 'green',
      musicPath: null,
      beats: [
        {from: 0, duration: 60, still: 'hook', kicker: 'Ideas', title: 'Your life is about four thousand weeks.', body: 'That is not a productivity slogan.'},
        {from: 60, duration: 90, still: 'world', kicker: 'Nonfiction', title: 'Four Thousand Weeks', body: 'Oliver Burkeman'},
        {from: 150, duration: 120, still: 'mechanism', kicker: 'The argument', title: 'You have to choose.', body: 'The list will not clear.'},
        {from: 270, duration: 120, still: 'catch', kicker: 'The catch', title: 'Not a step-by-step planner.', body: 'If you want a system, this is philosophy.'},
        {from: 390, duration: 150, still: 'hook', kicker: 'The reading rule', title: 'Read when the hacks stop working.', body: 'Skip it if you want a template.'},
      ],
    },
  },
  {
    id: 'Illustrated-06',
    coverId: 'Illustrated-06-Cover',
    output: 'out/illustrated/06-stoner.mp4',
    coverOutput: 'out/illustrated/06-stoner-cover.png',
    props: {
      folder: 'illustrated/cr-06',
      accent: colours.gold,
      field: 'wine',
      musicPath: null,
      beats: [
        {from: 0, duration: 60, still: 'hook', kicker: 'Backlist', title: 'A campus novel about work, not hijinks.', body: 'An ordinary life, treated as enough.'},
        {from: 60, duration: 90, still: 'world', kicker: 'Literary', title: 'Stoner', body: 'John Williams'},
        {from: 150, duration: 120, still: 'mechanism', kicker: 'What happens', title: 'A teacher. A bad marriage. Barely remembered.', body: 'The book takes that life seriously.'},
        {from: 270, duration: 120, still: 'catch', kicker: 'The catch', title: 'Sad, and slow.', body: 'Uneventful if you need plot machinery.'},
        {from: 390, duration: 150, still: 'hook', kicker: 'The reading rule', title: 'Read for quiet craft.', body: 'Not for campus hijinks.'},
      ],
    },
  },
  {
    id: 'Illustrated-07',
    coverId: 'Illustrated-07-Cover',
    output: 'out/illustrated/07-two-front-doors.mp4',
    coverOutput: 'out/illustrated/07-two-front-doors-cover.png',
    props: {
      folder: 'illustrated/cr-07',
      accent: colours.gold,
      field: 'green',
      musicPath: null,
      beats: [
        {from: 0, duration: 60, still: 'hook', kicker: 'Pairing', title: 'Two huge systems. Two front doors.', body: 'Pick the difficulty you actually want.'},
        {from: 60, duration: 90, still: 'world', kicker: 'Science fiction', title: 'Player of Games / Three-Body', body: 'Iain M. Banks / Cixin Liu'},
        {from: 150, duration: 120, still: 'mechanism', kicker: 'The difference', title: 'Games and politics, or cosmic mystery.', body: 'Same size. Different door.'},
        {from: 270, duration: 120, still: 'catch', kicker: 'The catch', title: 'Neither is a gentle on-ramp.', body: 'Do not rank them. Name the difficulty.'},
        {from: 390, duration: 150, still: 'hook', kicker: 'The reading rule', title: 'Pick the door, not the ranking.', body: 'Banks or Liu. Not a score.'},
      ],
    },
  },
];
