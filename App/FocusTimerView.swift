import SwiftUI
import WidgetKit

struct FocusTimerView: View {
    @State private var deadline: Date? = BaraStore.focusDeadline
    @State private var customMinutes = 25

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BaraPanel {
                    HStack {
                        MascotView(size: 92)
                        VStack(alignment: .leading) {
                            Text(BaraStrings.text("focus")).font(.title2.bold())
                            Text("25 / 50 / 90").font(.footnote)
                        }
                    }
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(0, Int((deadline ?? .distantPast).timeIntervalSince(context.date)))
                        Text(remaining > 0
                             ? String(format: "%02d:%02d:%02d", remaining / 3600, (remaining / 60) % 60, remaining % 60)
                             : BaraStrings.text("notRunning"))
                            .font(.system(size: remaining > 0 ? 35 : 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                }
                HStack(spacing: 9) {
                    ForEach([25, 50, 90], id: \.self) { count in
                        Button("\(count) min") { start(count) }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent).tint(BaraTheme.leaf)
                    }
                }
                BaraPanel {
                    Stepper("\(customMinutes) \(BaraStrings.text("minutes"))",
                            value: $customMinutes, in: 5...180, step: 5)
                    Button(BaraStrings.text("begin")) { start(customMinutes) }
                        .buttonStyle(.bordered)
                    Button(BaraStrings.text("end"), role: .destructive) { stop() }
                        .disabled(deadline == nil)
                }
                Text("This timer measures the focus session only. App restrictions need separate Screen Time authorization.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(BaraStrings.text("focus"))
        .onAppear { deadline = BaraStore.focusDeadline }
    }

    private func start(_ minutes: Int) {
        deadline = Date().addingTimeInterval(Double(minutes * 60))
        BaraStore.focusDeadline = deadline
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func stop() {
        deadline = nil
        BaraStore.focusDeadline = nil
        WidgetCenter.shared.reloadAllTimelines()
    }
}
