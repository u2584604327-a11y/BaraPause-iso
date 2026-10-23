import SwiftUI
import WidgetKit

struct FocusView: View {
    @AppStorage(SharedConfig.focusEndKey,store: SharedConfig.defaults) private var focusEnd = 0.0
    @AppStorage("language",store: SharedConfig.defaults) private var lang = "system"
    @AppStorage("focusPresetMinutes",store:SharedConfig.defaults) private var selectedMinutes=25

    private func tr(_ key:String)->String { TextKey.label(key,lang: lang) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                CapyMascot().frame(height: 180)
                TimelineView(.periodic(from: .now,by: 1)) { context in
                    let seconds=Int(max(0,focusEnd-context.date.timeIntervalSince1970))
                    VStack {
                        Text(seconds > 0 ? tr("active") : tr("noFocus"))
                            .font(.headline)
                        Text(String(format:"%02d:%02d:%02d",seconds/3600,seconds/60%60,seconds%60))
                            .font(.system(size: 43,weight: .bold,design: .rounded))
                            .monospacedDigit()
                    }
                }
                HStack(spacing:8) {
                    ForEach([25,50,90],id:\.self) { value in
                        Button("\(value) \(tr("minutes"))") { selectedMinutes=value }
                            .buttonStyle(.bordered)
                            .tint(selectedMinutes==value ? .green : .secondary)
                    }
                }
                Stepper("\(selectedMinutes) \(tr("minutes"))",
                        value:$selectedMinutes,in:5...180,step:5)
                Button {
                    SharedConfig.startFocus(minutes: selectedMinutes)
                    focusEnd=SharedConfig.defaults.double(forKey: SharedConfig.focusEndKey)
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label(tr("focusStart"),systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    SharedConfig.endFocus()
                    focusEnd=0
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label(tr("focusStop"),systemImage: "stop.circle")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(.bordered)
                Text(tr("shieldNote"))
                    .foregroundStyle(.secondary).font(.footnote)
            }.padding(22)
        }
    }
}
