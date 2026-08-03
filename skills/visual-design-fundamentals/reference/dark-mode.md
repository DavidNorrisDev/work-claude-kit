# Dark mode

Dark mode is not an inverted light mode — build it for its own goals.

- Don't flip colours. Dark surfaces need *more* separation from each other than light ones to stay legible; collapse contrast for light, widen it for dark.
- Create depth with elevation, not shadow: a surface that sits above another is *lighter* than it (there are effectively no shadows in dark mode).
- Favour light greys over pure white for body text to reduce eye strain; reserve white for the most important elements. Desaturate bright accents a touch.
- SwiftUI: use adaptive colours (asset catalogue light/dark variants or semantic `Color`s) and Materials for elevation; never two literal palettes maintained by hand.
- **Check:** is dark mode designed as its own palette with elevation-based depth, not a mechanical inverse?
