#  Studyo.io Assessment Mini-App
A small app written in Swift done in less than a day for the quick purpose of iOS Engineer Internship Test 
at [Studyo](https://studyo.io/).

## Features

Following the specified tasks under two documents provided for the test, within this app has 3 Features:

### Frame-by-Frame Animation
- The frame images was compressed as a single `zip` file on my own discretion for the sake of simplicity of tracking the files. Added a dependency to an open-source `Zip` using SPM to assist with decompressing on runtime.
- A small logic was applied to handle reverse reading of read files, from the most zoomed-in frame to the most zoomed-out frame
- Each frame is loaded eagerly into memory as `UIImage` for ease of rendering.
- Frame animation is using basic `Timer` API and with the help of Array `Iterator` to trace each frame. Normal `for-loop` won't do here in my opinion.

### Video Player
- UI-wise, simply disable the `VideoPlayer` View, then wrap it as child of a `ZStack` then add the custom controls on top of it.
- Made a `CustomPlayer`, subclassing `AVPlayer`. Added Rewind and Fast-forward methods.
- Tracking Pause/Play state and elapsed duration are done via old-school Swift's KVO approach against built-in `AVPlayer` and `AVPlayerItem` APIs. Specifically for playback duration, a specific observer is installed via `addPeriodicTimeObserver`.
- Video Metadata are hardcoded into `Firestore`.
- Sample loads the reference obtained from the first video metadata I hardcoded at Firestore.
- **TEST NOTE**: Since I didn't put any Loading indicators, while loading, the screen will simply shows `Video Player` text on screen. 

### TikTok Feature Copy of Vertical Video Swiping
- Current sample uses 3 hard-coded video references at `Firestore`.
- Copied the implementation of my `CustomPlayer` from previous task, but simplified it.
- Tracking of preloaded buffer duration is done via KVO approach on `AVPlayerItem`'s `loadedTimeRanges` values.
- The implementation is far from perfect as I spent only a few hours to quick plan about it.
- **TEST NOTE**: There was no Loading indicators right now, if the player is not ready, a placeholder showing the technical metadata of the Video data will be shown instead.
