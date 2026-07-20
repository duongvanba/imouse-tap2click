import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let leftItem = NSMenuItem(title: "Tap left mouse to click", action: #selector(toggleLeft), keyEquivalent: "")
    private let rightItem = NSMenuItem(title: "Tap right mouse to context menu", action: #selector(toggleRight), keyEquivalent: "")
    private let doubleTapItem = NSMenuItem(title: "Double tap to double click", action: #selector(toggleDoubleTap), keyEquivalent: "")
    private var leftEnabled = false { didSet { updateChecks() } }
    private var rightEnabled = false { didSet { updateChecks() } }
    private var doubleTapEnabled = true { didSet { updateChecks() } }
    private var eventTap: CFMachPort?
    private var lastLeftTapTime: TimeInterval = 0
    private let hidMonitor = HIDMonitor()
    private let multitouchMonitor = MultitouchMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "Imou Tap2Click")
        statusItem.button?.toolTip = "Imou Tap2Click"

        let menu = NSMenu()
        leftItem.target = self
        rightItem.target = self
        menu.addItem(leftItem)
        menu.addItem(rightItem)
        doubleTapItem.target = self
        menu.addItem(doubleTapItem)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        updateChecks()
        hidMonitor.start()
        multitouchMonitor.start { [weak self] isLeft in
            DispatchQueue.main.async { self?.handleSurfaceTap(isLeft: isLeft) }
        }
    }

    private func updateChecks() {
        leftItem.state = leftEnabled ? .on : .off
        rightItem.state = rightEnabled ? .on : .off
        leftItem.title = "Tap left mouse to click"
        rightItem.title = "Tap right mouse to context menu"
        doubleTapItem.state = doubleTapEnabled ? .on : .off
        doubleTapItem.title = "Double tap to double click"
        let check = greenCheckImage()
        leftItem.onStateImage = check
        rightItem.onStateImage = check
        doubleTapItem.onStateImage = check
    }

    private func greenCheckImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus(); NSColor.systemGreen.setStroke()
        let path = NSBezierPath(); path.lineWidth = 2.2
        path.move(to: NSPoint(x: 2, y: 8)); path.line(to: NSPoint(x: 6, y: 3)); path.line(to: NSPoint(x: 14, y: 13)); path.stroke()
        image.unlockFocus(); return image
    }

    @objc private func toggleLeft() {
        guard requestAccessibilityIfNeeded() else { return }
        leftEnabled.toggle(); updateEventTap()
    }
    @objc private func toggleRight() {
        guard requestAccessibilityIfNeeded() else { return }
        rightEnabled.toggle(); updateEventTap()
    }
    @objc private func toggleDoubleTap() { doubleTapEnabled.toggle() }

    private func requestAccessibilityIfNeeded() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) { return true }
        // Explicitly open the exact Accessibility settings pane as a fallback.
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        return false
    }

    private func updateEventTap() {
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false) }
        guard leftEnabled || rightEnabled else { eventTap = nil; return }
        let mask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue)
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, refcon in
            guard type == .otherMouseDown, let refcon else { return Unmanaged.passUnretained(event) }
            let app = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
            let button = event.getIntegerValueField(.mouseEventButtonNumber)
            guard (button == 0 && app.leftEnabled) || (button != 0 && app.rightEnabled) else { return Unmanaged.passUnretained(event) }
            let mouseButton: CGMouseButton = button == 0 ? .left : .right
            CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: event.location, mouseButton: mouseButton)?.post(tap: .cghidEventTap)
            CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: event.location, mouseButton: mouseButton)?.post(tap: .cghidEventTap)
            return nil
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        if let eventTap, let source = CFMachPortCreateRunLoopSource(nil, eventTap, 0) { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
    }

    private func handleSurfaceTap(isLeft: Bool) {
        guard (isLeft && leftEnabled) || (!isLeft && rightEnabled) else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let isDoubleLeftTap = doubleTapEnabled && isLeft && now - lastLeftTapTime <= 0.45
        if isLeft { lastLeftTapTime = now }
        let location = NSEvent.mouseLocation
        let point = CGPoint(x: location.x, y: NSScreen.screens.first!.frame.height - location.y)
        let button: CGMouseButton = isLeft ? .left : .right
        let downType: CGEventType = isLeft ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = isLeft ? .leftMouseUp : .rightMouseUp
        let down = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point, mouseButton: button)
        let up = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: point, mouseButton: button)
        if isDoubleLeftTap {
            down?.setIntegerValueField(.mouseEventClickState, value: 2)
            up?.setIntegerValueField(.mouseEventClickState, value: 2)
        }
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
if let bundleIdentifier = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
    exit(0)
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
