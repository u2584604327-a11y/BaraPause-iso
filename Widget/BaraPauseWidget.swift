import Foundation
import SwiftUI
import WidgetKit

struct BaraEntry: TimelineEntry {
    let date: Date
    let focusUntil: Date?
}
struct BaraProvider: TimelineProvider {
    func placeholder(in context: Context) -> BaraEntry {
        BaraEntry(date: Date(), focusUntil: Date().addingTimeInterval(25 * 60))
    }
    func getSnapshot(in context: Context, completion: @escaping (BaraEntry) -> Void) {
        completion(BaraEntry(date: Date(), focusUntil: BaraStore.focusDeadline))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BaraEntry>) -> Void) {
        let entry = BaraEntry(date: Date(), focusUntil: BaraStore.focusDeadline)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60))))
    }
}
struct BaraWidgetView: View {
    let entry: BaraEntry
    @Environment(\.widgetFamily) private var family
    private let cocoa = Color(red: 0.31, green: 0.23, blue: 0.20)
    private let leaf = Color(red: 0.38, green: 0.58, blue: 0.36)
    var body: some View {
        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "leaf.fill").foregroundStyle(leaf)
                        Text("BaraPause").font(.headline).foregroundStyle(cocoa)
                    }
                    Spacer(minLength: 0)
                    if let until = entry.focusUntil, until > entry.date {
                        Text(until, style: .timer).font(.title3.bold())
                            .monospacedDigit().foregroundStyle(cocoa)
                    } else {
                        Text("🍃").font(.system(size: 34))
                        Text("Start focus").font(.footnote).foregroundStyle(cocoa)
                    }
                    Text("Tap to focus").font(.caption2).foregroundStyle(.secondary)
                }.widgetURL(URL(string: "barapause://focus"))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🍃").font(.title)
                        Text("BaraPause").font(.title3.bold()).foregroundStyle(cocoa)
                        Spacer()
                        if let until = entry.focusUntil, until > entry.date {
                            Text(until, style: .timer)
                                .monospacedDigit().font(.subheadline.bold()).foregroundStyle(leaf)
                        }
                    }
                    HStack(spacing: 10) {
                        Link(destination: URL(string: "barapause://search")!) {
                            Label("Search", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity).padding(10)
                        }.buttonStyle(.borderedProminent).tint(leaf)
                        Link(destination: URL(string: "barapause://focus")!) {
                            Label("Focus", systemImage: "timer")
                                .frame(maxWidth: .infinity).padding(10)
                        }.buttonStyle(.bordered)
                    }
                    Text("Open a public search link or start a focus session.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(13)
        .containerBackground(for: .widget) {
            Color(red: 0.98, green: 0.95, blue: 0.88)
        }
    }
}
struct BaraPauseWidget: Widget {
    let kind = "BaraPauseWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BaraProvider()) { entry in
            BaraWidgetView(entry: entry)
        }
        .configurationDisplayName("BaraPause")
        .description("Focus countdown and quick search shortcuts.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
@main
struct BaraWidgetBundle: WidgetBundle {
    var body: some Widget { BaraPauseWidget() }
}
