import React from 'react';
import {Composition} from 'remotion';
import {BookQuotesReel, type BookQuotesReelProps} from './BookQuotesReel';
import {CommunityReel, type CommunityReelProps} from './CommunityReel';
import {CarouselSlide, carouselSets} from './CarouselSlide';
import {AppStoreScreenshot, appStoreScreenshots} from './AppStoreScreenshot';
import {colours} from './theme';

const reelProps: BookQuotesReelProps = {
  hook: 'Still losing the lines you underlined?',
  captureTitle: 'Photograph the marked page.',
  captureBody: 'BookQuotes looks for the passage you marked, then lets you review it before saving.',
  libraryTitle: 'Keep the words. Find them again.',
  libraryBody: 'Build a searchable library organised by book, quote and reading status.',
  endTitle: 'Your books. Your best lines.',
  website: 'BookQuotes on the App Store',
  voiceoverPath: null,
};

const communityReels: Array<{id: string; props: CommunityReelProps}> = [
  {
    id: 'OneLinePerBook',
    props: {
      hook: 'Do not just count the books.',
      intro: 'Keep one line from every book you read this summer.',
      beats: [
        {
          label: 'Notice',
          title: 'Mark the line that follows you.',
          body: 'Not the cleverest line. The one you are still thinking about tomorrow.',
          accent: colours.rust,
        },
        {
          label: 'Keep',
          title: 'Give it a place outside the book.',
          body: 'Capture the marked page and review the words before saving.',
          accent: colours.gold,
          screen: 'screens/appstore/iphone/06_captured_page.png',
        },
        {
          label: 'Return',
          title: 'End summer with a reading memory.',
          body: 'A small collection of lines that shows what your reading actually gave you.',
          accent: colours.green,
          screen: 'screens/appstore/iphone/03_quote_detail.png',
        },
      ],
      endTitle: 'One book. One line.',
      endBody: 'A gentler summer reading challenge for people who want to remember, not race.',
    },
  },
  {
    id: 'AnnotationDebate',
    props: {
      hook: 'Underline, tabs, or pristine pages?',
      intro: 'Readers rarely agree about what a well-loved book should look like.',
      beats: [
        {
          label: 'The underliner',
          title: 'Straight to the sentence.',
          body: 'Fast, permanent, and impossible to pretend you did not feel something.',
          accent: colours.rust,
        },
        {
          label: 'The tabber',
          title: 'A colour for every kind of feeling.',
          body: 'Themes, characters, questions, heartbreak. There is probably a key.',
          accent: colours.gold,
        },
        {
          label: 'The archivist',
          title: 'Not a mark on the page.',
          body: 'The book stays immaculate. The notes live somewhere else entirely.',
          accent: colours.navy,
        },
      ],
      endTitle: 'No wrong answer.',
      endBody: 'Only very strong opinions. Which kind of reader are you?',
    },
  },
  {
    id: 'CommonplaceRitual',
    props: {
      hook: 'Your reading journal should not become homework.',
      intro: 'Try this ten-minute commonplace-book ritual once a week.',
      beats: [
        {
          label: 'Choose',
          title: 'Pick three marked lines.',
          body: 'Keep the passages that still feel alive after the book is closed.',
          accent: colours.gold,
          screen: 'screens/appstore/iphone/07_extraction_review.png',
        },
        {
          label: 'Context',
          title: 'Add one sentence about why.',
          body: 'A small note gives your future self more value than a complicated tag system.',
          accent: colours.rust,
        },
        {
          label: 'Revisit',
          title: 'Read one old line each Sunday.',
          body: 'A commonplace book becomes useful when its ideas return to your life.',
          accent: colours.green,
          screen: 'screens/appstore/iphone/03_quote_detail.png',
        },
      ],
      endTitle: 'Read. Mark. Return.',
      endBody: 'BookQuotes helps paper-book readers build a searchable commonplace library.',
    },
  },
  {
    id: 'FindTheLine',
    props: {
      hook: 'You remember the line. Not the book. Not the page.',
      intro: 'The most frustrating kind of reading memory.',
      beats: [
        {
          label: 'Capture',
          title: 'Keep it while the page is open.',
          body: 'Photograph the marked passage and check the extracted words.',
          accent: colours.rust,
          screen: 'screens/appstore/iphone/06_captured_page.png',
        },
        {
          label: 'Organise',
          title: 'Save it beside the book.',
          body: 'Title, author, page and your own note stay together.',
          accent: colours.gold,
          screen: 'screens/appstore/iphone/02_book_detail.png',
        },
        {
          label: 'Search',
          title: 'Find the thought again.',
          body: 'Search across your personal quote library when the wording returns to you.',
          accent: colours.green,
          screen: 'screens/appstore/iphone/04_search_results.png',
        },
      ],
      endTitle: 'Keep the line within reach.',
      endBody: 'BookQuotes turns marked paper pages into a searchable reading memory.',
    },
  },
];

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="BookQuotesMarkedPage"
      component={BookQuotesReel}
      durationInFrames={660}
      fps={30}
      width={1080}
      height={1920}
      defaultProps={reelProps}
    />
    {communityReels.map((reel) => (
      <Composition
        key={reel.id}
        id={reel.id}
        component={CommunityReel}
        durationInFrames={660}
        fps={30}
        width={1080}
        height={1920}
        defaultProps={reel.props}
      />
    ))}
    {carouselSets.flatMap((set) =>
      set.slides.map((slide, index) => (
        <Composition
          key={`${set.id}-${index}`}
          id={`${set.id}-${String(index + 1).padStart(2, '0')}`}
          component={CarouselSlide}
          durationInFrames={1}
          fps={30}
          width={1080}
          height={1350}
          defaultProps={{
            ...slide,
            series: set.series,
            index: index + 1,
            total: set.slides.length,
          }}
        />
      )),
    )}
    {(['iphone', 'ipad'] as const).flatMap((device) =>
      appStoreScreenshots.map((shot, index) => (
        <Composition
          key={`${device}-${shot.id}`}
          id={`AppStore-${device === 'iphone' ? 'iPhone' : 'iPad'}-${String(index + 1).padStart(2, '0')}`}
          component={AppStoreScreenshot}
          durationInFrames={1}
          fps={30}
          width={device === 'iphone' ? 1320 : 2064}
          height={device === 'iphone' ? 2868 : 2752}
          defaultProps={{
            title: shot.title,
            body: shot.body,
            accent: shot.accent,
            screen: `screens/appstore/${device}/${shot.source}`,
            step: index + 1,
            total: appStoreScreenshots.length,
            device,
          }}
        />
      )),
    )}
  </>
);
