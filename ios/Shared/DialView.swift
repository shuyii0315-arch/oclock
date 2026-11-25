import SwiftUI

/// The O'Clock face. Fills its frame as a square; the parent supplies the white card.
struct DialView: View {
    let hour: Double
    let style: DialStyle

    var body: some View {
        let _ = OClockFonts.registered
        let task = Schedule.task(at: hour)
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Group {
                switch style {
                case .sticker: StickerFace(hour: hour, task: task)
                case .marker: MarkerFace(hour: hour, task: task)
                }
            }
            .frame(width: 400, height: 400)
            .scaleEffect(side / 400)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Shared bits

private let drop = (color: Color.black.opacity(0.35), radius: 2.5, x: 1.5, y: 3.0)

private func sliceAngles(_ task: OTask) -> (Double, Double) {
    let a1 = task.start.truncatingRemainder(dividingBy: 12) * 30
    return (a1, a1 + (task.end - task.start) * 30)
}

/// The slice appears by growing out from the centre, and fades when the task ends.
private let sliceTransition = AnyTransition.asymmetric(
    insertion: .scale(scale: 0.55).combined(with: .opacity),
    removal: .opacity
)

// MARK: - Sticker

private struct StickerFace: View {
    let hour: Double
    let task: OTask?

    var body: some View {
        let hrA = hour.truncatingRemainder(dividingBy: 12) * 30
        let minA = (hour - hour.rounded(.down)) * 360
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let major = i % 3 == 0
                Dial.bar(x: 198, y: 18, w: 4, h: major ? 20 : 10, r: 2, angle: Double(i) * 30)
                    .fill(major ? Color(hex: 0x2A2520) : Color(hex: 0xB9B2A6))
            }

            if let task, let th = Schedule.themes[task.theme] {
                StickerSlice(task: task, theme: th)
                    .id(task.id)
                    .transition(sliceTransition)
                // during a task the clock hands step aside; one red hand shows how far into the slice you are
                Dial.bar(x: 198.5, y: 56, w: 3, h: 146, r: 1.5, angle: hrA)
                    .fill(Color(hex: 0xE8412C))
                    .shadow(color: drop.color, radius: drop.radius, x: drop.x, y: drop.y)
            } else {
                Group {
                    Dial.bar(x: 195, y: 98, w: 10, h: 107, r: 5, angle: hrA).fill(Color(hex: 0x1A1A1A))
                    Dial.bar(x: 197, y: 56, w: 6, h: 149, r: 3, angle: minA).fill(Color(hex: 0x1A1A1A))
                }
                .shadow(color: drop.color, radius: drop.radius, x: drop.x, y: drop.y)
            }

            ZStack {
                Circle().fill(Color(hex: 0xE8412C))
                    .overlay(Circle().stroke(Color(hex: 0xC8321E), lineWidth: 1.5))
                    .frame(width: 34, height: 34)
                Circle().fill(Color(hex: 0xEF4A32)).frame(width: 18, height: 18)
            }
            .shadow(color: drop.color, radius: drop.radius, x: drop.x, y: drop.y)
            .position(Dial.c)
        }
        .frame(width: 400, height: 400)
    }
}

private struct StickerSlice: View {
    let task: OTask
    let theme: Theme

    var body: some View {
        let (a1, a2) = sliceAngles(task)
        // read left-to-right (or top-to-bottom when the pointers are stacked): the first pointer gets the first word
        let tA = Dial.pt(a1, 170), tB = Dial.pt(a2, 170)
        let dx = tB.x - tA.x, dy = tB.y - tA.y
        let bFirst = abs(dx) > abs(dy) ? dx < 0 : dy < 0
        let wordA = bFirst ? task.w2 : task.w1
        let wordB = bFirst ? task.w1 : task.w2

        ZStack {
            wedge(a1, a2).fill(theme.wedge)

            ForEach([a1, a2], id: \.self) { a in
                Dial.bar(x: 192, y: 183, w: 180, h: 34, r: 1, angle: a - 90)
                    .fill(theme.bar)
                    .shadow(color: drop.color, radius: drop.radius, x: drop.x, y: drop.y)
            }
            EngravedWord(text: wordA, angle: a1, color: theme.letter)
            EngravedWord(text: wordB, angle: a2, color: theme.letter)

            // objects sit on top of the pointers and may lean slightly past the card edge
            ForEach(Array(theme.items.enumerated()), id: \.offset) { i, it in
                let place = placement(it, index: i, mid: (a1 + a2) / 2)
                Image(it.image)
                    .resizable()
                    .frame(width: place.w, height: place.h)
                    .shadow(color: .black.opacity(0.42), radius: 3, x: 0, y: 5)
                    .rotationEffect(.degrees(place.rot))
                    .position(place.p)
            }
        }
        .frame(width: 400, height: 400)
    }

    /// The slice reaches past the card, so the card's own corners cut it.
    private func wedge(_ a1: Double, _ a2: Double) -> Path {
        var p = Path()
        p.move(to: Dial.c)
        var a = a1
        while a < a2 { p.addLine(to: Dial.pt(a, 300)); a += 1 }
        p.addLine(to: Dial.pt(a2, 300))
        p.closeSubpath()
        return p
    }

    private func placement(_ it: SliceItem, index i: Int, mid: Double) -> (p: CGPoint, w: Double, h: Double, rot: Double) {
        let k = i == 0 ? 1.42 : 1.22, r = i == 0 ? 1.34 : 1.24
        var w = it.width * k
        var h = w * (Schedule.aspect[it.image] ?? 1)
        var p = Dial.pt(mid + it.angle * 1.15, it.radius * r)
        let cx = min(372, max(28, p.x)), cy = min(340, max(34, p.y))
        let over = abs(cx - p.x) + abs(cy - p.y)
        // near the edge: shrink rather than slide inward over the pointers
        if over > 0 { let f = max(0.72, 1 - over / 160); w *= f; h *= f }
        p = CGPoint(x: (p.x + cx) / 2, y: (p.y + cy) / 2)
        let rot = it.rotation * 1.3 + (i % 2 == 1 ? 5 : -4)
        return (p, w, h, rot)
    }
}

/// A word pressed into the pointer: two inner shadows, dark from the top-left edge and a faint light rim
/// on the opposite side, and nothing outside the letters.
private struct EngravedWord: View {
    let text: String
    let angle: Double
    let color: Color

    var body: some View {
        Text(text)
            .font(.custom(OClockFonts.archivo, size: 23))
            .tracking(0.3)
            .foregroundStyle(
                color
                    .shadow(.inner(color: Color(hex: 0x00141F, opacity: 0.55), radius: 0.7, x: 1.4, y: 1.6))
                    .shadow(.inner(color: .white.opacity(0.22), radius: 0.7, x: -0.8, y: -0.9))
            )
            .fixedSize()
            .rotationEffect(.degrees(Dial.flipped(angle) ? 180 : 0))
            .position(x: 294, y: 200)
            .frame(width: 400, height: 400)
            .rotationEffect(.degrees(angle - 90))
    }
}

// MARK: - Hand-drawn

private let ink = Color(hex: 0x7A3B2E)

private struct MarkerFace: View {
    let hour: Double
    let task: OTask?

    var body: some View {
        let hrA = hour.truncatingRemainder(dividingBy: 12) * 30
        let minA = (hour - hour.rounded(.down)) * 360
        ZStack {
            Dial.ring(176, 0).fill(Color(hex: 0xFBF7EC))
            Dial.ring(177, 40).stroke(ink, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            Dial.ring(171, 170).stroke(ink.opacity(0.8), style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))

            if let task, let th = Schedule.themes[task.theme] {
                MarkerSlice(task: task, theme: th, hrA: hrA)
                    .id(task.id)
                    .transition(sliceTransition)
            } else {
                numerals(hidden: { _ in false })
                Dial.handLine(hrA, 95, bend: 3).stroke(ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                Dial.handLine(minA, 140, bend: -3).stroke(ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }

            Circle().fill(ink).frame(width: 14, height: 14).position(Dial.c)
        }
        .frame(width: 400, height: 400)
    }
}

private struct Numeral: Identifiable {
    let n: Int
    let a: Double
    var id: Int { n }
}

private let numeralAngles = [Numeral(n: 12, a: 0), Numeral(n: 3, a: 90), Numeral(n: 6, a: 180), Numeral(n: 9, a: 270)]

private func numerals(hidden: @escaping (Double) -> Bool) -> some View {
    ForEach(numeralAngles) { item in
        if !hidden(item.a) {
            let p = Dial.pt(item.a, 140)
            Text("\(item.n)")
                .font(.custom(OClockFonts.hand, size: 44))
                .foregroundStyle(ink)
                .fixedSize()
                .position(x: p.x, y: p.y + 2)
        }
    }
}

private struct MarkerSlice: View {
    let task: OTask
    let theme: Theme
    let hrA: Double

    var body: some View {
        let (a1, a2) = sliceAngles(task)
        let mid = (a1 + a2) / 2
        let tag = Dial.pt(a1 - 38, 86)
        let tagWidth = Double(task.label.count) * 13.5 // close enough to hide numerals the tag would cover

        ZStack {
            wedge(a1, a2)
                .offsetBy(dx: -3, dy: 2)
                .fill(theme.soft)
                .clipShape(Dial.ring(176, 0))

            numerals(hidden: { a in
                let na = a < a1 - 5 ? a + 360 : a
                if na >= a1 - 6 && na <= a2 + 6 { return true }
                let p = Dial.pt(a, 140)
                return abs(p.x - tag.x) < tagWidth / 2 + 34 && abs(p.y - tag.y) < 40
            })

            Dial.handLine(hrA, 150, bend: 2)
                .stroke(Color(hex: 0xE86A5A), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            ForEach(Array(theme.marker.enumerated()), id: \.offset) { _, it in
                let w = it.width, h = w * (Schedule.aspect[it.image] ?? 1)
                Image(it.image)
                    .resizable()
                    .frame(width: w, height: h)
                    .rotationEffect(.degrees(it.rotation))
                    .position(Dial.pt(mid + it.angle, it.radius))
            }

            Dial.handLine(a1, 168, bend: 3).stroke(ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            Dial.handLine(a2, 168, bend: -3).stroke(ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))

            Text(task.label)
                .font(.custom(OClockFonts.hand, size: 30.8))
                .tracking(0.6)
                .foregroundStyle(Color(hex: 0x1A1A1A))
                .fixedSize()
                .padding(.horizontal, 11)
                .frame(height: 30)
                .background(Rectangle().fill(Color(hex: 0xFF86D9)))
                .rotationEffect(.degrees(-4))
                .position(tag)
        }
        .frame(width: 400, height: 400)
    }

    private func wedge(_ a1: Double, _ a2: Double) -> Path {
        var p = Path()
        p.move(to: Dial.c)
        var a = a1
        while a <= a2 + 0.01 { p.addLine(to: Dial.pt(a, Dial.wob(a, 168))); a += 3 }
        p.addLine(to: Dial.pt(a2, Dial.wob(a2, 168)))
        p.closeSubpath()
        return p
    }
}
