# Ascender

A macOS utility for inspecting and adjusting font ascender and descender metrics with live visual feedback.

Ascender provides a way to adjust a font's vertical alignment. This solves common font rendering problems when developing iOS applications. Thanks to Andy Yardley for the [original article](https://www.andyyardley.com/2012/04/24/custom-ios-fonts-and-how-to-fix-the-vertical-position-problem/).


![Ascender Preview](Screenshots/preview.png)

---

## Requirements

- macOS
- Xcode 16+
- [Apple Font Tools](https://developer.apple.com/fonts/) installed
  (part of the Apple Fonts package)

> Ascender relies on Apple’s font tooling rather than custom binary parsing.

## Features

- Drag & drop `.ttf` / `.otf` fonts
- Visualizes:
  - Baseline
  - Ascender
  - Descender
- Live adjustment via sliders
- Displays values in points (derived from font units)
- Exports a modified font using Apple Font Tools
- Non-destructive workflow (original font is never modified)

## How it works

1. A font is copied into a temporary working directory
2. Apple Font Tools (`ftxdumperfuser`, `ftxsplitfont`, `ftxbuildfont`) are used to:
   - Inspect font tables
   - Apply updated ascender / descender values
   - Rebuild the font
3. The user is prompted to save the adjusted font
4. Temporary files are cleaned up automatically