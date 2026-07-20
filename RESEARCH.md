# Magic Mouse Tap-to-Click Research

## Goal

Recognize a light tap on either half of an Apple Magic Mouse touch surface without requiring the mechanical button to be pressed, then generate a primary or secondary click.

## Native macOS behavior

macOS supports trackpad tap-to-click, but it does not expose an equivalent setting for Magic Mouse. Accessibility Dwell can click after the pointer remains stationary, but it does not recognize Magic Mouse surface taps.

## Public event APIs

The first implementation used a Quartz event tap and listened for `otherMouseDown`. This did not work because a surface tap does not produce a normal mouse-button event.

An `IOHIDManager` monitor was then used to inspect raw HID values. The connected device was identified as:

- Product: Apple Magic Mouse
- Transport: Bluetooth HID
- Vendor ID: `0x004C`
- Product ID: `0x0269`

After filtering to that device, the public HID values contained pointer movement on Generic Desktop usages X (`0x30`) and Y (`0x31`), but no contact geometry or tap event. This established that public IOHID input values are insufficient for surface-tap recognition.

## MultitouchSupport

Apple's private `MultitouchSupport.framework` exposes raw contact frames through functions including:

- `MTDeviceCreateList`
- `MTRegisterContactFrameCallback`
- `MTDeviceStart`

Each frame contains one or more `MTTouch` records with a contact stage, timestamp, identifier, and normalized surface position.

Observed one-finger samples were clearly separated:

- Left-side taps: normalized X approximately `0.17–0.19`
- Right-side taps: normalized X approximately `0.83–0.87`

The implementation therefore uses normalized X `0.5` as the left/right boundary.

## Gesture recognition

A contact is treated as a tap when:

1. It begins at contact stage `3`.
2. It ends at out-of-range stage `7`.
3. Duration is less than 350 milliseconds.
4. Total normalized movement is less than `0.08`.

These constraints avoid interpreting normal scrolling or swiping as a click. A recognized tap is posted at the current pointer position with a matching `CGEvent` down/up pair.

## Permissions

Reading multitouch frames does not replace the requirement for Accessibility permission. macOS requires that permission before the application may synthesize global mouse events. The app checks trust with `AXIsProcessTrustedWithOptions` and opens the appropriate System Settings pane if access is missing.

## Distribution considerations

`MultitouchSupport.framework` is undocumented. Its ABI may change without notice, and use of private frameworks prevents Mac App Store distribution. Direct distribution, code signing, and notarization are the practical release path.

## Open-source reference

The MultitouchSupport declarations were informed by the open-source [MiddleClick](https://github.com/artginzburg/MiddleClick) project and its `MoreTouch` wrapper. The local implementation remains intentionally small and focused on one-finger left/right Magic Mouse taps.
