# Agent Instructions

### How it works
Read this entire file before starting any task.

## Self-Correcting Rules Engine
This file contains a growing ruleset that improves over time. **At session start, read the entire "Learned Rules" section before doing anything.**

### Instructions for Agent
1. When the user corrects you or you make a mistake, **immediately append a new rule** to the "Learned Rules" section at the bottom of this file.
2. Rules are numbered sequentially and written as clear, imperative instructions.
3. Format: `N. [CATEGORY] Never/Always do X - because Y.`
4. Categories: `[STYLE]`, `[CODE]`, `[ARCH]`, `[TOOL]`, `[PROCESS]`, `[DATA]`, `[UX]`, `[OTHER]`
5. Before starting any task, scan all rules below for relevant constraints.
6. If two rules conflict, the higher-numbered (newer) rule wins.
7. Never delete rules. If a rule becomes obsolete, append a new rule that supersedes it.

### When to add a rule
- User explicitly corrects your output ("no, do it this way")
- User rejects a file, approach, or pattern
- You hit a bug caused by a wrong assumption about this iOS codebase
- User states a preference ("always use x", "never do y")
- Simulator or build failure reveals an iOS/macOS platform-specific constraint

### Rule format examples (iOS Tailored)
- `[ARCH] Always organize production code into MVVM folders ('App/', 'Constants/', 'Models/', 'ViewModels/', 'Views/', 'Engine/', 'Resources/') - standard production architecture.`
- `[CODE] Always store tunable gameplay balance in 'GameConstants.swift' - prevents scattered hardcoded values across multiple files.`
- `[TOOL] Always target the booted simulator destination using its explicit ID with xcodebuild - avoids simulator boot timeouts.`

## Learned Rules
<!-- New rules are appended below this line. Do not edit above this section. -->
1. [ARCH] Always organize code in strict MVVM architecture (`App/`, `Constants/`, `Models/`, `ViewModels/`, `Views/`, `Engine/`, `Resources/`) - ensures production-grade maintainability, clear separation of concerns, and clean testability.
2. [CODE] Always define and consume tunable gameplay balance, scoring multipliers, audio identifiers, and colors in `GameConstants.swift` - enables single-file game tuning without modifying multiple source files.
3. [CODE] Never mutate `AVAudioPlayer.volume` unless `abs(player.volume - targetVolume) > 0.01` - prevents firing redundant CoreAudio property updates and simulator LoudnessManager warnings.
4. [CODE] Always deduplicate audio playback via `currentLoadedSong` before re-instantiating `AVAudioPlayer` - avoids memory leaks and simulator Mach message IPC audio queue overloads.
5. [CODE] Always pool at most 2 simultaneous voices per sound effect for rhythmic gameplay - prevents CoreAudio audio device timeouts (AQMEIO) on Apple Silicon simulator bridges.
6. [CODE] Always configure and activate `AVAudioSession.sharedInstance()` synchronously with category `.playback` at engine initialization - guarantees audio decoders initialize with an active session.
7. [CODE] Always normalize USDZ node materials (`normalizeCharacterMaterials`) and offset bounding-box pivot heights when dynamically swapping 3D avatars - prevents clothing texture glitches and floor sinking.
8. [UX] Always adhere to native iOS Human Interface Guidelines for authentication buttons with corner radius 22pt and high-contrast accessibility - maintains premium Apple aesthetics.
9. [DATA] Always isolate persistent player state (scores, coins, unlocks, volume preferences) in `PlayerProfile` backed by `UserDefaults`, and provide a complete session purge in `logout()` - guarantees compliance with App Store review guidelines.
10. [TOOL] Always specify the explicit simulator ID in `xcodebuild` (e.g. `-destination 'id=...'`) and check booted status with `xcrun simctl list` - prevents destination resolution failures and empty platform buildable warnings.
11. [PROCESS] Always verify that all unit and UI test suites (`GrooveGamesTests`, `GrooveGamesUITests`) compile and pass with 100% success rate before completing tasks and pushing commits.
12. [CODE] Always define user-facing gameplay strings and judgment labels (e.g. 'FEVER BONUS!', 'PERFECT!', 'MISS!') in `GameConstants.swift` rather than inline string literals - enables centralized localization and single-file text adjustments.
13. [TOOL] Always pass `-parallel-testing-enabled NO` to `xcodebuild test` when running UITests on iOS simulator destinations - avoids simulator clone runner launch contention and FBSOpenApplicationServiceErrorDomain code 1 crashes.
14. [PROCESS] Always ensure App Store Connect distribution compliance by stripping alpha channels from 1024x1024 app store marketing icons (RGB 24-bit), setting UIRequiresFullScreen for iPad landscape games, providing PrivacyInfo.xcprivacy for UserDefaults access (CA92.1), setting ITSAppUsesNonExemptEncryption to NO, and incrementing CURRENT_PROJECT_VERSION - prevents automated App Store Connect validation and TestFlight processing rejections.
