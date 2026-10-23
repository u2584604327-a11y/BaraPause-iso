import SwiftUI
import WidgetKit

struct BaraEntry: TimelineEntry {
    let date: Date
    let focusEnd: TimeInterval
    let recent: String
}

struct BaraProvider: TimelineProvider {
    func placeholder(in context: Context) -> BaraEntry {
        BaraEntry(date:Date(),focusEnd:0,recent:"BaraPause")
    }
    func getSnapshot(in context: Context,completion:@escaping (BaraEntry)->Void) {
        completion(entry())
    }
    func getTimeline(in context: Context,completion:@escaping (Timeline<BaraEntry>)->Void) {
        completion(Timeline(entries:[entry()],policy:.after(Date().addingTimeInterval(60))))
    }
    private func entry() -> BaraEntry {
        BaraEntry(date:Date(),
            focusEnd:SharedConfig.defaults.double(forKey:SharedConfig.focusEndKey),
            recent:SharedConfig.defaults.stringArray(forKey:SharedConfig.searchHistoryKey)?.first ?? "")
    }
}

struct BaraWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry:BaraEntry

    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            HStack {
                Image(systemName:"leaf.circle.fill").font(.title2).foregroundStyle(.green)
                Text("BaraPause").font(.headline)
                Spacer()
            }
            if entry.focusEnd > entry.date.timeIntervalSince1970 {
                Text("专注进行中").font(.caption).foregroundStyle(.secondary)
                Text(Date(timeIntervalSince1970:entry.focusEnd),style:.timer)
                    .font(.title3.monospacedDigit())
            } else {
                Text("轻轻守门，专心一点").font(.subheadline)
            }
            if family != .systemSmall {
                HStack(spacing:10) {
                    Link(destination:URL(string:"barapause://search")!) {
                        Label("搜索",systemImage:"magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    Link(destination:URL(string:"barapause://focus")!) {
                        Label("专注",systemImage:"timer")
                    }
                    .buttonStyle(.bordered)
                }
                if !entry.recent.isEmpty {
                    Text("最近：\(entry.recent)").font(.caption2)
                        .lineLimit(1).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading)
        .padding(8)
        .containerBackground(Color(red:0.96,green:0.93,blue:0.85),for:.widget)
        .widgetURL(URL(string:"barapause://search"))
    }
}

struct BaraWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:"BaraPauseQuickWidget",provider:BaraProvider()) { entry in
            BaraWidgetView(entry:entry)
        }
        .configurationDisplayName("BaraPause")
        .description("专注倒计时、搜索和快捷启动")
        .supportedFamilies([.systemSmall,.systemMedium])
    }
}
@main
struct BaraWidgetBundle: WidgetBundle {
    var body: some Widget { BaraWidget() }
}
