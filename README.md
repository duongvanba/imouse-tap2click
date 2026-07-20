# Imouse Clicker

A tiny native macOS menu-bar utility that adds tap-to-click gestures to Apple Magic Mouse.

- Tap the left half of the touch surface to perform a primary click.
- Tap the right half to open the context menu.
- Enable or disable each gesture independently from the menu bar.
- Automatically prompts for Accessibility permission when required.

## Requirements

- macOS 13 or newer
- Apple Magic Mouse
- Swift 5.9 or newer
- Accessibility permission for generating mouse events

## Run from source

```bash
swift run
```

The app runs only in the menu bar and does not show a Dock icon.

## Build the application bundle

```bash
./build_app.sh
```

This creates `Imouse Clicker.app` in the repository root. Move it to `/Applications`, open it, then enable it under:

`System Settings → Privacy & Security → Accessibility`

## How it works

Magic Mouse surface contacts are not exposed as ordinary mouse-button events through public `IOHIDManager` APIs. Imouse Clicker reads contact frames from Apple's private `MultitouchSupport.framework`, recognizes short low-movement touches, divides the surface at its horizontal midpoint, and emits the corresponding click with `CGEvent`.

See [RESEARCH.md](RESEARCH.md) for implementation details and captured findings.

## Limitations

- `MultitouchSupport.framework` is undocumented and may change in future macOS releases.
- Apps using private frameworks are not eligible for distribution through the Mac App Store.
- The current gesture thresholds are tuned for an Apple Magic Mouse with vendor ID `0x004C` and product ID `0x0269`.

## License

No license has been selected yet. All rights are reserved by the repository owner.
