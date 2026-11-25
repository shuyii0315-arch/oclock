import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configuration: touch and hold the widget → Edit Widget → Style

enum StyleOption: String, AppEnum {
    case sticker, handDrawn

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Style")
    static var caseDisplayRepresentations: [StyleOption: DisplayRepresentation] = [
        .sticker: "Sticker",
        .handDrawn: "Hand-drawn",
    ]

    var dialStyle: DialStyle { self == .sticker ? .sticker : .marker }
}

struct StyleIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "O'Clock"
    static var description = IntentDescription("Choose how your clock looks.")

    @Parameter(title: "Style", default: .sticker)
    var style: StyleOption

    init() {}
    init(style: StyleOption) { self.style = style }
}

// MARK: - Timeline: one entry per minute, so the hands keep moving and a slice opens right on time

struct ClockEntry: TimelineEntry {
    let date: Date
    let style: DialStyle
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .today(at: 14.5), style: .sticker)
    }

    func snapshot(for configuration: StyleIntent, in context: Context) async -> ClockEntry {
        // the widget gallery shows a moment with a task, so people see what it does
        ClockEntry(date: context.isPreview ? .today(at: 14.5) : .now, style: configuration.style.dialStyle)
    }

    func timeline(for configuration: StyleIntent, in context: Context) async -> Timeline<ClockEntry> {
        let cal = Calendar.current
        let now = Date.now
        let minute = cal.date(from: cal.dateComponents([.year, .month, .day, .hour, .minute], from: now)) ?? now
        let entries = (0..<90).map { i in
            ClockEntry(date: minute.addingTimeInterval(Double(i) * 60), style: configuration.style.dialStyle)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Widget

struct OClockWidgetView: View {
    let entry: ClockEntry

    var body: some View {
        DialView(hour: entry.date.hourOfDay, style: entry.style)
            .containerBackground(.white, for: .widget)
    }
}

struct OClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "OClock", intent: StyleIntent.self, provider: Provider()) { entry in
            OClockWidgetView(entry: entry)
        }
        .configurationDisplayName("O'Clock")
        .description("Your day, one slice at a time.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

@main
struct OClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        OClockWidget()
    }
}

// MARK: - Xcode canvas previews (no phone needed)

#Preview("Sticker", as: .systemSmall) {
    OClockWidget()
} timeline: {
    ClockEntry(date: .today(at: 13.9), style: .sticker)
    ClockEntry(date: .today(at: 14.5), style: .sticker)
    ClockEntry(date: .today(at: 9.2), style: .sticker)
    ClockEntry(date: .today(at: 20.1), style: .sticker)
}

#Preview("Hand-drawn", as: .systemSmall) {
    OClockWidget()
} timeline: {
    ClockEntry(date: .today(at: 13.9), style: .marker)
    ClockEntry(date: .today(at: 14.5), style: .marker)
    ClockEntry(date: .today(at: 11.6), style: .marker)
}
