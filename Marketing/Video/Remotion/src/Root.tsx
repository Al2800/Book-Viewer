import React from 'react';
import {Composition} from 'remotion';
import {BookQuotesReel, type BookQuotesReelProps} from './BookQuotesReel';
import {CarouselSlide, carouselSets} from './CarouselSlide';
import {AppStoreScreenshot, appStoreScreenshots} from './AppStoreScreenshot';

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
