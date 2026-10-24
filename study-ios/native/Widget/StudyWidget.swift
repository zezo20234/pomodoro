import WidgetKit
import SwiftUI
import ActivityKit

@main
struct StudyWidgetBundle: WidgetBundle {
    var body: some Widget { StudyLiveActivity() }
}

struct TimerLabel: View {
    let end: Date
    var body: some View {
        Text(timerInterval: Date()...max(end, Date().addingTimeInterval(1)), countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

struct StudyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyAttributes.self) { ctx in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ctx.state.phase).font(.headline)
                    Text(ctx.state.cycleText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                TimerLabel(end: ctx.state.end).font(.title2.bold())
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text(ctx.state.phase).font(.headline) }
                DynamicIslandExpandedRegion(.trailing) { TimerLabel(end: ctx.state.end).font(.title3.bold()) }
                DynamicIslandExpandedRegion(.bottom) { Text(ctx.state.cycleText).font(.caption) }
            } compactLeading: {
                Image(systemName: "book.fill")
            } compactTrailing: {
                TimerLabel(end: ctx.state.end).frame(width: 52)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
