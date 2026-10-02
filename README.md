# SeeMyMessage

A simple iOS LED message board app built with **SwiftUI**.

SeeMyMessage turns your iPhone into a full-screen scrolling LED display. Type a message, adjust the scrolling speed and LED appearance, then display it in landscape mode.

## Features

* 📱 Native iOS app built with SwiftUI
* 🔴 Red dot-matrix LED text
* ↔️ Smooth continuous horizontal scrolling
* ⚡ Adjustable scrolling speed
* 🔠 Adjustable LED text size
* ↔️ Adjustable message gap
* ⏯️ Pause and resume scrolling
* 🔄 Seamless message looping
* 🔒 Works completely offline
* 🌙 Keeps the screen awake while displaying
* 📐 Landscape display mode
* ♿ Basic accessibility labels
* 🚫 No account, backend, analytics, ads, or external dependencies

## Screens

### Home

Enter your message and configure the display settings.

### LED Display

The message is displayed as a large red dot-matrix LED sign on a black background.

## Tech Stack

* **Language:** Swift
* **UI:** SwiftUI
* **Platform:** iOS
* **IDE:** Xcode
* **Architecture:** SwiftUI state-driven UI
* **Rendering:** SwiftUI Canvas
* **Persistence:** None
* **Backend:** None
* **External Dependencies:** None

## Project Structure

```text
SeeMyMessage/
├── SeeMyMessageApp.swift
├── Models/
│   └── DisplaySettings.swift
├── Views/
│   ├── HomeView.swift
│   ├── DisplayView.swift
│   ├── LEDStyle.swift
│   ├── LEDLetterFont.swift
│   ├── LEDNumberFont.swift
│   └── LEDMessageView.swift
└── Services/
    └── OrientationLock.swift
```

## How It Works

The app has two main screens:

```text
Home
  │
  ├── Enter message
  ├── Set scroll speed
  ├── Set LED text size
  └── Set message gap
          │
          ▼
      LED Display
          │
          ├── Continuous scrolling
          ├── Pause / Resume
          └── Exit
```

The LED characters are rendered using a custom **5×7 dot-matrix font**.

The display uses `Canvas` rendering instead of creating individual SwiftUI views for every LED dot. This keeps the animation lightweight and allows long messages to scroll smoothly.

Scrolling is based on elapsed time and pixels-per-second rather than frame count, making the animation independent of frame rate.

## Display Settings

| Setting       |       Range | Default |
| ------------- | ----------: | ------: |
| Scroll Speed  | 30–250 px/s | 80 px/s |
| LED Text Size |     8–32 px |   28 px |
| Message Gap   |   50–500 px |  280 px |

## Supported Characters

The custom LED font currently supports:

* A–Z
* 0–9
* Space
* `.`
* `,`
* `!`
* `?`
* `-`
* `_`
* `:`
* `/`
* `'`
* `(`
* `)`

Lowercase letters are displayed using the corresponding uppercase LED glyph.

Unsupported characters are displayed using a placeholder glyph.

## Performance

The display renderer was optimized to avoid creating thousands of individual SwiftUI shape views during animation.

The current renderer:

* Uses `Canvas`
* Uses precomputed glyph masks
* Precomputes message geometry
* Updates scrolling using elapsed time
* Uses a single shadow per message copy
* Repeats the message seamlessly
* Maintains coverage for long messages and different screen sizes

## Requirements

* macOS with Xcode
* iOS device or simulator
* Swift / SwiftUI support for the project's deployment target

## Running the Project

1. Clone the repository.
2. Open `SeeMyMessage.xcodeproj` in Xcode.
3. Select an iPhone simulator or physical iPhone.
4. Build and run the project.

For a physical device, configure your Apple Developer signing team in:

**Xcode → Project → Target → Signing & Capabilities**

## Privacy

SeeMyMessage does not require an account and does not collect or transmit user data.

The app has:

* No backend
* No analytics
* No advertising SDK
* No tracking
* No Firebase
* No external API
* No network-dependent functionality

Messages and display settings are used locally while the app is running.

## Status

**Personal project — development complete for the current feature set.**

The current version is focused on providing a simple, smooth LED message-board experience on iPhone.

## License

This project is currently for personal use.

No open-source license has been applied.
