# Find Chords — App Store release package

Status: release candidate preparation  
Source branch: `modern-ios`  
Bundle ID: `com.tucuatro.chords`  
Marketing version: **1.1**  
Release-candidate build: **12**

## Release sequencing

Find Chords is the first public iPhone submission. Cuatro Tuner follows after this release path is proven.

## Product naming

- App Store name: **TuCuatro Chords Finder**
- Device display name: **TuCuatro Chords**
- In-app identity: **TuCuatro Chords**
- Subtitle: **Chords for cuatro and more**

## App Store description

Find clear chord diagrams for Venezuelan cuatro, guitar, ukulele, and cavaquinho.

Search chords quickly, switch instruments, explore available positions, and keep the chord library ready when you are offline. When an internet connection is available, the app can check TuCuatro's public chord library for updates.

TuCuatro Chords Finder is designed as a focused reference for practice, teaching, rehearsals, and learning new chord shapes.

Features:
- Venezuelan cuatro, guitar, ukulele, and cavaquinho chord diagrams
- Fast chord search and selection
- Multiple chord positions when available
- Offline chord library
- Simple native interface built for quick musical reference

No account is required.

## Keywords

`cuatro,chords,guitar,ukulele,cavaquinho,chord finder,venezuela,music,practice`

## Categories

- Primary: **Music**
- Secondary: **Education**

## URLs

- Marketing URL: **https://tucuatro.com/chords/**
- Support URL: **https://tucuatro.com/faq/**
- Privacy Policy URL: **https://tucuatro.com/privacy-policy/**

## App Privacy

Current native-code audit:
- no account or login;
- no advertising;
- no analytics or telemetry SDK;
- no microphone, camera, contacts, photos, or location permission;
- only public chord-library manifest/JSON download from `tucuatro.com`;
- downloaded chord data is cached locally.

Final App Privacy declaration from Web review:
- Data type: **Diagnostics -> Other Diagnostic Data**
- Purpose: **App Functionality**
- Linked to user: **No**
- Used for tracking: **No**

Reason: ordinary retained web-infrastructure/access-log metadata from chord manifest/library requests. Do not declare account/contact/advertising/location data for the current native app.

## Age rating

The product contains chord diagrams and utility UI only. In the App Information age-rating questionnaire, answer the content/capability questions according to the actual build (no social/chat/UGC, violence, sexual content, gambling, medical content, etc.). Expected resulting rating: **4+**.

## Export compliance

The project declares `ITSAppUsesNonExemptEncryption = NO`. The app uses Apple's standard networking stack for HTTPS and does not implement non-exempt encryption.

## App Review notes

No account or sign-in is required.

The app is a chord-reference utility for Venezuelan cuatro, guitar, ukulele, and cavaquinho. Reviewers can:
1. switch instruments from the instrument selector;
2. search and select chords;
3. change chord positions when multiple positions are available;
4. use the bundled chord library without an account.

The app may check TuCuatro's public chord-library endpoint for updated chord data when online. It does not include purchases, subscriptions, microphone recording, user-generated content, or account creation.

## Screenshot set

Use truthful screenshots from build **12** only. Prepare at least these three portrait screenshots for the required iPhone display class:

1. **Venezuelan Cuatro** — main chord view with a clear multi-position chord.
2. **Ukulele** — a chord with a single available position, showing the corrected compact Position 1 chip rather than a full-width bar.
3. **Chord chooser/search** — search or chord-selection sheet open, showing the app's fast reference workflow.

Optional fourth screenshot: another instrument such as Guitar or Cavaquinho.

Do not add feature claims or mock screens that are not present in build 12.

## Release-candidate acceptance

Before archiving:
- pull `modern-ios`;
- run the existing local brand/Xcode preparation script used by the accepted builds;
- verify AppIcon, launch treatment, in-app TuCuatro identity, chord search, instrument switching, diagram accuracy, and the compact single-position control;
- confirm Xcode shows version **1.1** / build **12**;
- archive and upload the exact accepted build.

## App Store Connect version record

The current App Store Connect draft visibly says iOS version **1.0**, while the accepted native/TestFlight line is **1.1**. Before selecting build 12, change the editable App Store version field to **1.1** (or create the 1.1 version record if Apple requires it). Do not downgrade the accepted binary back to 1.0 merely to match the stale draft.

## Final founder gate

Mobile owns preparation through a submission-ready App Store Connect page. The remaining founder-only gate is final review/authorization of the public submission and any Apple account authentication Apple requests.
