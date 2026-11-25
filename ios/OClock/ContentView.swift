import SwiftUI
import WidgetKit

/// The app is a preview of the widget: scrub through the day and switch styles.
struct ContentView: View {
    @State private var style: DialStyle = .sticker
    @State private var hour: Double = min(22, max(7, Date.now.hourOfDay))

    private var task: OTask? { Schedule.task(at: hour) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    DialView(hour: hour, style: style)
                        .frame(width: 300, height: 300)
                        .background(.white, in: RoundedRectangle(cornerRadius: 64, style: .continuous))
                        .clipShape(RoundedRectangle(cornerRadius: 64, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 24, y: 10)
                        .animation(.spring(duration: 0.6, bounce: 0.3), value: task?.id)
                        .animation(.easeInOut(duration: 0.3), value: style)
                        .padding(.top, 8)

                    Picker("Style", selection: $style) {
                        ForEach(DialStyle.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preview time").font(.subheadline.weight(.medium))
                            Spacer()
                            Text(clock(hour)).monospacedDigit().foregroundStyle(.secondary)
                            Button("Now") { withAnimation { hour = min(22, max(7, Date.now.hourOfDay)) } }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        Slider(value: $hour, in: 7...22)
                    }

                    VStack(spacing: 0) {
                        ForEach(Schedule.tasks) { t in
                            let th = Schedule.themes[t.theme]
                            Button {
                                withAnimation { hour = t.start + 0.4 }
                            } label: {
                                HStack(spacing: 12) {
                                    Circle().fill(th?.bar ?? .gray).frame(width: 10, height: 10)
                                    Text(t.w1.capitalized).foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(clock(t.start)) – \(clock(t.end))")
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if t.id != Schedule.tasks.last?.id { Divider() }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Add the widget: touch and hold the Home Screen, tap Edit → Add Widget, and choose O'Clock. To switch between Sticker and Hand-drawn, touch and hold the widget and tap Edit Widget.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(24)
            }
            .background(Color(hex: 0xF2F1ED))
            .navigationTitle("O'Clock")
            .onAppear { WidgetCenter.shared.reloadAllTimelines() }
        }
    }

    private func clock(_ h: Double) -> String {
        let total = Int((h * 60).rounded())
        let hh = total / 60, mm = total % 60
        let h12 = hh % 12 == 0 ? 12 : hh % 12
        return mm == 0 ? "\(h12) \(hh < 12 ? "AM" : "PM")" : String(format: "%d:%02d %@", h12, mm, hh < 12 ? "AM" : "PM")
    }
}

#Preview {
    ContentView()
}
