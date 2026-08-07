import React from 'react';
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {colours, sans, serif} from './theme';

export type SciFiPost = {
  id: string;
  eyebrow: string;
  hook: string;
  title: string;
  author: string;
  premise: string;
  reservation: string;
  question: string;
  accent: string;
  motif: 'orbit' | 'grid' | 'signal' | 'note';
  cover?: string;
};

export const sciFiPosts: SciFiPost[] = [
  {
    id: 'SciFi-01-PlayerOfGames',
    eyebrow: 'Reading route / the Culture',
    hook: 'Want to try the Culture without a giant primer?',
    title: 'The Player of Games',
    author: 'Iain M. Banks',
    premise: 'A star player enters a society where a game decides who rules.',
    reservation: 'A strong researched entry point, but still an ideas-first 1980s novel.',
    question: 'Where did you start with the Culture?',
    accent: '#B75A44',
    motif: 'orbit',
    cover: 'assets/scifi-covers/the-player-of-games.jpg',
  },
  {
    id: 'SciFi-02-CultureRoutes',
    eyebrow: 'Five routes / the Culture',
    hook: 'There is no single correct way into the Culture.',
    title: 'Choose the book for the question you want.',
    author: 'Iain M. Banks',
    premise: 'Game and power. War and memory. Minds and ships. Grief. An outside view.',
    reservation: 'This is a reading map, not a ranking.',
    question: 'Which route sounds like yours?',
    accent: '#4A7B62',
    motif: 'grid',
  },
  {
    id: 'SciFi-03-IdeasThroughAGame',
    eyebrow: 'Reader fit / sci-fi',
    hook: 'For readers who like big ideas disguised as a game.',
    title: 'The Player of Games',
    author: 'Iain M. Banks',
    premise: 'A tight way into questions of power, strategy and the society around the board.',
    reservation: 'Choose another route if you want a character-led intimate novel first.',
    question: 'Ideas first, or characters first?',
    accent: '#D8A267',
    motif: 'grid',
    cover: 'assets/scifi-covers/the-player-of-games.jpg',
  },
  {
    id: 'SciFi-04-CultureOrder',
    eyebrow: 'Reader question / the Culture',
    hook: 'Culture reading order is a real reader argument.',
    title: 'Publication order or the book that pulls you in?',
    author: 'Iain M. Banks',
    premise: 'These novels share a universe, but each approaches it from a different angle.',
    reservation: 'There is no compulsory route.',
    question: 'What would you tell a new reader?',
    accent: '#2D475F',
    motif: 'note',
  },
  {
    id: 'SciFi-05-TwoBigSystems',
    eyebrow: 'Reader pairing / science fiction',
    hook: 'Two huge sci-fi systems. Two very different ways in.',
    title: 'The Culture or Three-Body?',
    author: 'Iain M. Banks / Cixin Liu',
    premise: 'Choose games and politics, or scientific mystery and cosmic scale.',
    reservation: 'This is a reader-fit pairing, not a verdict on either series.',
    question: 'Which are you reaching for?',
    accent: '#8D5C65',
    motif: 'signal',
  },
  {
    id: 'SciFi-06-ThreeBodyFit',
    eyebrow: 'Reader fit / trilogy',
    hook: 'Should you read The Three-Body Problem?',
    title: 'Start here if you want scale.',
    author: 'Cixin Liu, translated by Ken Liu',
    premise: 'History, science and a mystery that opens onto an extinction-level threat.',
    reservation: 'Its conceptual scale may suit you better than character-intimacy-led fiction.',
    question: 'What makes hard sci-fi work for you?',
    accent: '#54768A',
    motif: 'signal',
  },
  {
    id: 'SciFi-07-ThreeBodyOrder',
    eyebrow: 'Reading route / trilogy',
    hook: 'The Three-Body trilogy: start here.',
    title: 'Read the three in order.',
    author: 'The Three-Body Problem -> The Dark Forest -> Death\'s End',
    premise: 'The published trilogy continues its central story across all three books.',
    reservation: 'Check your edition for translator credits.',
    question: 'Save this before you begin.',
    accent: '#4A7B62',
    motif: 'orbit',
  },
  {
    id: 'SciFi-08-BigBookPermission',
    eyebrow: 'Reader note / long books',
    hook: 'A big sci-fi book is not homework.',
    title: 'Choose an entry point. Read slowly. Stop honestly.',
    author: 'A BookQuotes reader note',
    premise: 'The right book is the one that meets the way you actually want to read.',
    reservation: 'Leaving a book is allowed.',
    question: 'Which long book are you taking slowly?',
    accent: '#A85C4A',
    motif: 'note',
  },
  {
    id: 'SciFi-09-WhatDoYouWantFirst',
    eyebrow: 'Reader question / science fiction',
    hook: 'What do you want first from science fiction?',
    title: 'An idea. A world. A character. A sentence.',
    author: 'A BookQuotes reader question',
    premise: 'The answer changes which recommendation will actually fit.',
    reservation: 'No option is more serious than another.',
    question: 'Pick one, then name the book.',
    accent: '#D8A267',
    motif: 'grid',
  },
  {
    id: 'SciFi-10-KeepTheLine',
    eyebrow: 'Reader ritual / BookQuotes',
    hook: 'Keep the line that made the big idea land.',
    title: 'Capture the line. Review it. Keep it.',
    author: 'BookQuotes',
    premise: 'A private library for the thoughts you want to find again.',
    reservation: 'Use only an owned page or licensed demonstration text.',
    question: 'What is the last line you saved?',
    accent: '#4A7B62',
    motif: 'note',
  },
];

const Motif: React.FC<{kind: SciFiPost['motif']; accent: string; progress: number}> = ({
  kind,
  accent,
  progress,
}) => {
  if (kind === 'orbit') {
    return <div style={{position: 'absolute', width: 760, height: 760, border: `3px solid ${accent}`, borderRadius: '50%', opacity: 0.22, right: -280, top: 430, transform: `rotate(${progress * 40}deg)`}} />;
  }
  if (kind === 'grid') {
    return <div style={{position: 'absolute', width: 850, height: 850, opacity: 0.12, right: -180, top: 520, backgroundImage: `linear-gradient(${accent} 2px, transparent 2px), linear-gradient(90deg, ${accent} 2px, transparent 2px)`, backgroundSize: '92px 92px', transform: `rotate(${12 - progress * 6}deg)`}} />;
  }
  if (kind === 'signal') {
    return <><div style={{position: 'absolute', width: 620, height: 3, backgroundColor: accent, opacity: 0.45, top: 690, right: -80, transform: `rotate(${progress * 10 - 18}deg)`}} /><div style={{position: 'absolute', width: 390, height: 3, backgroundColor: accent, opacity: 0.3, top: 805, right: -40, transform: `rotate(${progress * -8 + 16}deg)`}} /></>;
  }
  return <div style={{position: 'absolute', width: 720, height: 300, right: -110, top: 520, borderTop: `4px solid ${accent}`, borderBottom: `4px solid ${accent}`, opacity: 0.18, transform: `rotate(${-8 + progress * 5}deg)`}} />;
};

const BookJacket: React.FC<{src: string; progress: number}> = ({src, progress}) => (
  <div style={{position: 'absolute', right: 96, top: 1180, width: 304, height: 465, padding: 11, backgroundColor: colours.white, boxShadow: '0 28px 54px rgba(23, 26, 31, 0.24)', opacity: progress, transform: `translateY(${interpolate(progress, [0, 1], [44, 0])}px) rotate(4deg)`}}>
    <Img src={staticFile(src)} style={{width: '100%', height: '100%', objectFit: 'cover'}} />
  </div>
);

export const SciFiReadingRouteReel: React.FC<{post: SciFiPost}> = ({post}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const inProgress = spring({frame, fps, config: {damping: 160}});
  const reveal = spring({frame: frame - 50, fps, config: {damping: 180}});
  const close = spring({frame: frame - 320, fps, config: {damping: 180}});
  const y = interpolate(inProgress, [0, 1], [38, 0]);

  return (
    <AbsoluteFill style={{backgroundColor: colours.paper, color: colours.ink, overflow: 'hidden'}}>
      <div style={{position: 'absolute', inset: 34, border: `2px solid ${colours.line}`}} />
      <div style={{position: 'absolute', left: 34, top: 34, bottom: 34, width: 14, backgroundColor: post.accent}} />
      <Motif kind={post.motif} accent={post.accent} progress={inProgress} />
      <div style={{position: 'absolute', top: 76, left: 84, right: 84, display: 'flex', justifyContent: 'space-between', fontFamily: sans, fontSize: 23, fontWeight: 800, letterSpacing: 0, textTransform: 'uppercase', color: colours.muted}}>
        <span>BookQuotes reading routes</span><span>SCI-FI</span>
      </div>
      <div style={{position: 'absolute', left: 84, right: 84, top: 250, transform: `translateY(${y}px)`, opacity: inProgress}}>
        <div style={{maxWidth: 850, fontFamily: serif, fontSize: 91, lineHeight: 0.98, fontWeight: 700}}>{post.hook}</div>
        <div style={{marginTop: 52, display: 'inline-block', padding: '16px 22px', backgroundColor: post.accent, color: colours.white, fontFamily: sans, fontSize: 23, fontWeight: 800, letterSpacing: 0, textTransform: 'uppercase'}}>{post.eyebrow}</div>
      </div>
      <div style={{position: 'absolute', left: 84, right: 84, top: post.cover ? 800 : 960, opacity: reveal, transform: `translateY(${interpolate(reveal, [0, 1], [24, 0])}px)`}}>
        <div style={{maxWidth: post.cover ? 540 : 860, fontFamily: serif, fontSize: 64, lineHeight: 1.05, fontWeight: 700, color: post.accent}}>{post.title}</div>
        <div style={{marginTop: 17, fontFamily: sans, fontSize: 29, fontWeight: 750, color: colours.navy}}>{post.author}</div>
        <div style={{marginTop: 42, maxWidth: post.cover ? 570 : 820, fontFamily: serif, fontSize: 48, lineHeight: 1.24, fontWeight: 650}}>{post.premise}</div>
        <div style={{marginTop: 40, maxWidth: post.cover ? 540 : 840, borderLeft: `8px solid ${post.accent}`, paddingLeft: 22, fontFamily: sans, fontSize: 27, lineHeight: 1.35, fontWeight: 650, color: colours.muted}}>Know before you start: {post.reservation}</div>
      </div>
      {post.cover ? <BookJacket src={post.cover} progress={reveal} /> : null}
      <div style={{position: 'absolute', left: 84, right: 84, bottom: 100, opacity: close, transform: `translateY(${interpolate(close, [0, 1], [20, 0])}px)`}}>
        <div style={{fontFamily: serif, fontSize: 47, lineHeight: 1.13, fontWeight: 700}}>{post.question}</div>
        <div style={{marginTop: 25, display: 'flex', justifyContent: 'space-between', fontFamily: sans, fontSize: 22, fontWeight: 750, color: colours.muted}}><span>@bookquotes.app</span><span>Researched reading route</span></div>
      </div>
    </AbsoluteFill>
  );
};
