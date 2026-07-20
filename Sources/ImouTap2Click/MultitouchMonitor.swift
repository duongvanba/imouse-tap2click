import Foundation
import MultitouchSupport

@_silgen_name("MTDeviceCreateList")
private func MTDeviceCreateList() -> Unmanaged<CFMutableArray>?

private var touchStarts: [Int32: (time: Double, x: Float, y: Float)] = [:]
private var detectedTap: ((Bool) -> Void)?

private let touchCallback: MTFrameCallbackFunction = { _, touches, count, timestamp, frame in
    guard count > 0, let touches else { return }
    let values = (0..<Int(count)).map { i in
        let t = touches[i]
        if t.stage.rawValue == 3 {
            touchStarts[t.identifier] = (timestamp, t.normalizedVector.position.x, t.normalizedVector.position.y)
        } else if t.stage.rawValue == 7, let start = touchStarts.removeValue(forKey: t.identifier) {
            let dx = t.normalizedVector.position.x - start.x
            let dy = t.normalizedVector.position.y - start.y
            let distance = sqrt(dx * dx + dy * dy)
            if timestamp - start.time < 0.35 && distance < 0.08 {
                detectedTap?(start.x < 0.5)
            }
        }
        return "id=\(t.identifier) stage=\(t.stage.rawValue) x=\(t.normalizedVector.position.x) y=\(t.normalizedVector.position.y)"
    }.joined(separator: " | ")
    let line = "[\(Date())] frame=\(frame) touches=\(count) \(values)\n"
    let url = URL(fileURLWithPath: "/tmp/imouse-touch.log")
    if let data = line.data(using: .utf8), let handle = try? FileHandle(forWritingTo: url) {
        handle.seekToEndOfFile(); handle.write(data); try? handle.close()
    } else { try? line.write(to: url, atomically: true, encoding: .utf8) }
}

final class MultitouchMonitor {
    private var devices: [MTDevice] = []
    func start(onTap: @escaping (Bool) -> Void) {
        detectedTap = onTap
        devices = MTDeviceCreateList()?.takeUnretainedValue() as? [MTDevice] ?? []
        for device in devices { device.register(contactFrameCallback: touchCallback); device.start(runMode: 0) }
    }
}
