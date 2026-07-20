import Foundation
import IOKit.hid

final class HIDMonitor {
    private var manager: IOHIDManager?

    func start() {
        let m = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        manager = m
        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x004C,
            kIOHIDProductIDKey as String: 0x0269
        ]
        IOHIDManagerSetDeviceMatching(m, matching as CFDictionary)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterInputValueCallback(m, { _, _, refcon, value in
            guard let refcon else { return }
            let monitor = Unmanaged<HIDMonitor>.fromOpaque(refcon).takeUnretainedValue()
            let element = IOHIDValueGetElement(value)
            let page = IOHIDElementGetUsagePage(element)
            let usage = IOHIDElementGetUsage(element)
            let number = IOHIDValueGetIntegerValue(value)
            monitor.log("page=0x\(String(page, radix: 16)) usage=0x\(String(usage, radix: 16)) value=\(number)")
        }, context)
        IOHIDManagerScheduleWithRunLoop(m, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerOpen(m, IOOptionBits(kIOHIDOptionsTypeNone))
        log("Magic Mouse HID monitor started (vendor=0x004c product=0x0269)")
    }

    private func log(_ message: String) {
        let line = "[\(Date())] \(message)\n"
        let url = URL(fileURLWithPath: "/tmp/imouse-hid.log")
        if let data = line.data(using: .utf8), let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile(); handle.write(data); try? handle.close()
        } else { try? line.write(to: url, atomically: true, encoding: .utf8) }
    }
}
