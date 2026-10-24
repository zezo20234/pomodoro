import Foundation
import Capacitor
import ActivityKit

/// Shows the running study timer as a Live Activity.
/// `scheduled` is false, so the web app falls back to local notifications with alarm.wav.
@objc(LiveActivityPlugin)
public class LiveActivityPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveActivityPlugin"
    public let jsName = "LiveActivity"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setAlarms", returnType: CAPPluginReturnPromise)
    ]

    @objc func setAlarms(_ call: CAPPluginCall) {
        let raw = call.getArray("alarms") as? [[String: Any]] ?? []
        var items: [(Date, String)] = []
        for d in raw {
            guard let ms = (d["endMs"] as? NSNumber)?.doubleValue else { continue }
            let title = (d["title"] as? String) ?? "Study timer"
            items.append((Date(timeIntervalSince1970: ms / 1000), title))
        }
        items.sort { $0.0 < $1.0 }
        let sorted = items
        Task { await self.apply(sorted) }
        call.resolve(["scheduled": false])
    }

    private func apply(_ items: [(Date, String)]) async {
        let existing = Activity<StudyAttributes>.activities
        guard let first = items.first, ActivityAuthorizationInfo().areActivitiesEnabled else {
            for a in existing { await a.end(nil, dismissalPolicy: .immediate) }
            return
        }
        let state = StudyAttributes.ContentState(
            phase: first.1, end: first.0,
            cycleText: items.count > 1 ? "\(items.count) phases left" : "Last phase")
        let content = ActivityContent(state: state, staleDate: first.0.addingTimeInterval(60))
        if let a = existing.first {
            await a.update(content)
        } else {
            _ = try? Activity<StudyAttributes>.request(
                attributes: StudyAttributes(title: "Study Together"), content: content, pushType: nil)
        }
    }
}
