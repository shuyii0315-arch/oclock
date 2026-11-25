import SwiftUI
import CoreText

// MARK: - Model

/// One object placed inside a task's slice.
/// angle: offset in degrees from the middle of the slice, radius: distance from the centre,
/// width: in dial units (the dial is drawn on a 400 × 400 board), rotation: degrees.
struct SliceItem {
    let image: String
    let angle: Double
    let radius: Double
    let width: Double
    let rotation: Double
}

struct Theme {
    let wedge: Color     // sticker slice
    let bar: Color       // sticker pointers
    let letter: Color    // engraved words on the pointers
    let soft: Color      // hand-drawn slice
    let items: [SliceItem]
    let marker: [SliceItem]
}

struct OTask: Identifiable, Hashable {
    let theme: String
    let start: Double    // hours, 0–24
    let end: Double
    let w1: String
    let w2: String
    var id: String { "\(theme)-\(start)" }
    var label: String { "\(w1) \(w2)" }
}

enum DialStyle: String, CaseIterable, Identifiable {
    case sticker, marker
    var id: String { rawValue }
    var title: String { self == .sticker ? "Sticker" : "Hand-drawn" }
}

enum Schedule {
    static let tasks: [OTask] = [
        OTask(theme: "work",  start: 8.5,  end: 11,   w1: "WORK",  w2: "O'CLOCK"),
        OTask(theme: "cook",  start: 11,   end: 13,   w1: "COOK",  w2: "O'CLOCK"),
        OTask(theme: "clean", start: 14,   end: 16,   w1: "CLEAN", w2: "O'CLOCK"),
        OTask(theme: "move",  start: 17,   end: 19,   w1: "GYM",   w2: "O'CLOCK"),
        OTask(theme: "bath",  start: 19.5, end: 21.5, w1: "CAT",   w2: "O'CLOCK"),
    ]

    static func task(at hour: Double) -> OTask? {
        tasks.first { hour >= $0.start && hour < $0.end }
    }

    static let themes: [String: Theme] = [
        "work": Theme(wedge: Color(hex: 0x2340C9), bar: Color(hex: 0xFFD23F), letter: Color(hex: 0xE3A90A), soft: Color(hex: 0xCADCF6),
                      items: [.init(image: "laptop", angle: 0, radius: 114, width: 84, rotation: -8),
                              .init(image: "notes", angle: 14, radius: 158, width: 60, rotation: -14),
                              .init(image: "mug", angle: -14, radius: 160, width: 58, rotation: 10)],
                      marker: [.init(image: "m-laptop", angle: -6, radius: 108, width: 84, rotation: 0),
                               .init(image: "m-mug", angle: 15, radius: 152, width: 50, rotation: 4)]),
        "cook": Theme(wedge: Color(hex: 0x1E5E45), bar: Color(hex: 0xFF9A4D), letter: Color(hex: 0xE66F18), soft: Color(hex: 0xF8D9B0),
                      items: [.init(image: "pan", angle: 0, radius: 112, width: 92, rotation: -10),
                              .init(image: "tomato", angle: 14, radius: 156, width: 62, rotation: 8),
                              .init(image: "spoon", angle: -14, radius: 160, width: 90, rotation: 30)],
                      marker: [.init(image: "m-pan", angle: -6, radius: 108, width: 86, rotation: 0),
                               .init(image: "m-tomato", angle: 15, radius: 152, width: 56, rotation: 4)]),
        "clean": Theme(wedge: Color(hex: 0x141414), bar: Color(hex: 0x5DB6DE), letter: Color(hex: 0x2592C8), soft: Color(hex: 0xCFE9E3),
                       items: [.init(image: "bucket", angle: -1, radius: 112, width: 76, rotation: -6),
                               .init(image: "sponge", angle: 14, radius: 156, width: 58, rotation: 22),
                               .init(image: "brush", angle: -13, radius: 160, width: 84, rotation: -28)],
                       marker: [.init(image: "m-bucket", angle: -6, radius: 106, width: 62, rotation: 0),
                                .init(image: "m-brush", angle: 15, radius: 150, width: 54, rotation: 6)]),
        "move": Theme(wedge: Color(hex: 0x5B3FD1), bar: Color(hex: 0xC8F04A), letter: Color(hex: 0x8DB814), soft: Color(hex: 0xE2F2A6),
                      items: [.init(image: "dumbbell", angle: 0, radius: 114, width: 88, rotation: -12),
                              .init(image: "bottle", angle: 14, radius: 156, width: 34, rotation: 14),
                              .init(image: "sneaker", angle: -14, radius: 160, width: 80, rotation: -18)],
                      marker: [.init(image: "m-dumbbell", angle: -6, radius: 106, width: 90, rotation: -10),
                               .init(image: "m-sneaker", angle: 15, radius: 152, width: 66, rotation: 6)]),
        "bath": Theme(wedge: Color(hex: 0x2E6F8E), bar: Color(hex: 0xFFB8CB), letter: Color(hex: 0xE77799), soft: Color(hex: 0xF3E98A),
                      items: [.init(image: "cat", angle: 4, radius: 120, width: 58, rotation: 0),
                              .init(image: "bowl", angle: -13, radius: 146, width: 46, rotation: 0)],
                      marker: [.init(image: "m-cat", angle: 3, radius: 112, width: 70, rotation: 0),
                               .init(image: "m-bowl", angle: -14, radius: 140, width: 50, rotation: 0)]),
    ]

    /// height / width of each cut-out
    static let aspect: [String: Double] = [
        "bucket": 1.125, "brush": 0.744, "sponge": 1.338, "laptop": 0.956, "mug": 1.032, "notes": 0.944,
        "pan": 0.747, "tomato": 1.014, "spoon": 0.95, "dumbbell": 0.675, "sneaker": 0.581, "bottle": 3.495,
        "cat": 1.8, "bowl": 0.881,
        "m-laptop": 0.906, "m-mug": 1.268, "m-pan": 0.9, "m-tomato": 0.817, "m-bucket": 1.436, "m-brush": 1.304,
        "m-dumbbell": 0.45, "m-sneaker": 0.486, "m-cat": 1.212, "m-bowl": 0.632,
    ]
}

// MARK: - Geometry (everything is laid out on a 400 × 400 board, centre at 200, 200)

enum Dial {
    static let c = CGPoint(x: 200, y: 200)

    /// a: degrees clockwise from 12 o'clock
    static func pt(_ a: Double, _ r: Double) -> CGPoint {
        let t = a * .pi / 180
        return CGPoint(x: 200 + r * sin(t), y: 200 - r * cos(t))
    }

    /// slightly irregular radius, so hand-drawn circles never look compass-perfect
    static func wob(_ a: Double, _ base: Double) -> Double {
        base + 4 * sin(a * 0.05 + 1.3) + 2.5 * sin(a * 0.13 + 0.4) + 1.5 * sin(a * 0.31)
    }

    static func ring(_ base: Double, _ phase: Double) -> Path {
        var p = Path()
        var a = 0.0
        while a <= 360 {
            let q = pt(a, wob(a + phase, base))
            if a == 0 { p.move(to: q) } else { p.addLine(to: q) }
            a += 3
        }
        p.closeSubpath()
        return p
    }

    /// a rounded rect standing on the board, then turned around the centre
    static func bar(x: Double, y: Double, w: Double, h: Double, r: Double, angle: Double) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
            .applying(turn(angle))
    }

    static func turn(_ deg: Double) -> CGAffineTransform {
        CGAffineTransform(translationX: 200, y: 200)
            .rotated(by: deg * .pi / 180)
            .translatedBy(x: -200, y: -200)
    }

    /// a slightly bent stroke from the centre, like a pen line
    static func handLine(_ a: Double, _ r: Double, bend: Double) -> Path {
        var p = Path()
        p.move(to: c)
        p.addQuadCurve(to: pt(a, r), control: pt(a + bend, r * 0.5))
        return p
    }

    static func flipped(_ a: Double) -> Bool {
        let n = (a.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return n > 180 && n < 360
    }
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension Date {
    /// hours since midnight, e.g. 14.5 for 2:30 PM
    var hourOfDay: Double {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60 + Double(c.second ?? 0) / 3600
    }

    /// today at the given hour, for previews
    static func today(at hour: Double) -> Date {
        let start = Calendar.current.startOfDay(for: .now)
        return start.addingTimeInterval(hour * 3600)
    }
}

/// Fonts ship inside the app and the widget; register them once per process.
enum OClockFonts {
    static let archivo = "ArchivoSemiBold-Black"
    static let hand = "NanumPen-Regular"

    static let registered: Bool = {
        for name in ["Archivo-Black", "NanumPen"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        return true
    }()
}
