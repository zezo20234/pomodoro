import ActivityKit
import Foundation

struct StudyAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
        var end: Date
        var cycleText: String
    }
    var title: String
}
