import SwiftUI
import UIKit
import QuickdressCore

// MARK: - Stub: the one main action on a screen

/// A black strip with a perforated top edge and notched ends.
struct StubShape: Shape {
    func path(in rect: CGRect) -> Path {
        var cutouts = Path()
        let notch = min(11, rect.height / 4)
        cutouts.addEllipse(in: CGRect(x: rect.minX - notch, y: rect.midY - notch, width: notch * 2, height: notch * 2))
        cutouts.addEllipse(in: CGRect(x: rect.maxX - notch, y: rect.midY - notch, width: notch * 2, height: notch * 2))
        var x = rect.minX + 10
        while x < rect.maxX - 14 {
            cutouts.addRect(CGRect(x: x, y: rect.minY, width: 4.5, height: 3.6))
            x += 9
        }
        return Path(rect).subtracting(cutouts)
    }
}

struct StubButtonStyle: ButtonStyle {
    var showsArrow = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .font(.statement(31, relativeTo: .title2))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 5)
                .padding(.horizontal, showsArrow ? 64 : 28)
            if showsArrow && isEnabled {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.trailing, 28)
                }
                .accessibilityHidden(true)
            }
        }
        .foregroundStyle(isEnabled ? Color.white : Theme.buttonOffInk)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(StubShape().fill(isEnabled ? Theme.ink : Theme.buttonOff))
        .opacity(configuration.isPressed ? 0.82 : 1)
        .contentShape(Rectangle())
    }
}

/// A plain underlined text button in the statement face ("Not now", "Open Settings").
struct UnderlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.statement(21, relativeTo: .body))
            .foregroundStyle(Theme.ink)
            .padding(.top, 4)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.ink).frame(height: 2).offset(y: 1) }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

// MARK: - Tag: the numbered paper tag on every garment

struct TagShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cut = rect.height * 0.25
        var outline = Path()
        outline.move(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        outline.addLine(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        outline.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        outline.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        outline.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        outline.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        outline.closeSubpath()
        let hole = Path(ellipseIn: CGRect(x: rect.minX + cut * 0.55, y: rect.minY + cut * 0.55, width: 7, height: 7))
        return outline.subtracting(hole)
    }
}

struct TagView: View {
    let text: String
    var colour: Color
    var scale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            Text(text)
                .font(.ticket(15 * scale, relativeTo: .caption, medium: true))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .fixedSize()
            Rectangle().fill(Theme.ink).frame(height: 1.2 * scale)
        }
        .padding(.leading, 22 * scale)
        .padding(.trailing, 10 * scale)
        .padding(.vertical, 10 * scale)
        .background(TagShape().fill(colour).shadow(color: .black.opacity(0.22), radius: 1.5, y: 1.5))
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - Garment: the photo, cut out, with its tag tied on

struct GarmentView: View {
    let image: UIImage?
    let isCutOut: Bool
    let tagText: String
    let tagColour: Color
    var tagScale: CGFloat = 1
    var showsString = true

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                Group {
                    if let image {
                        if isCutOut {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .shadow(color: Color(red: 0.16, green: 0.13, blue: 0.09).opacity(0.22), radius: 6, y: 6)
                        } else {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                        }
                    } else {
                        Image(systemName: "tshirt")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.secondaryInk)
                    }
                }
                .frame(width: size.width, height: size.height)

                if showsString {
                    Path { path in
                        path.move(to: CGPoint(x: size.width * 0.48, y: size.height * 0.10))
                        path.addQuadCurve(
                            to: CGPoint(x: size.width * 0.60, y: size.height * 0.33),
                            control: CGPoint(x: size.width * 0.50, y: size.height * 0.28)
                        )
                    }
                    .stroke(Theme.string, lineWidth: 2.2)
                }
                TagView(text: tagText, colour: tagColour, scale: tagScale)
                    .rotationEffect(.degrees(-13), anchor: .topLeading)
                    .offset(x: size.width * 0.58, y: size.height * 0.31)
            }
        }
    }
}

// MARK: - Receipt paper with torn edges

struct TornPaperShape: Shape {
    var seed: UInt64 = 7

    func path(in rect: CGRect) -> Path {
        var generator = SeededGenerator(seed: seed)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 4))
        var x = rect.minX + 6
        while x <= rect.maxX {
            path.addLine(to: CGPoint(x: x, y: rect.minY + 1 + Double.random(in: 0...5, using: &generator)))
            x += 6
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
        x = rect.maxX - 6
        while x >= rect.minX {
            path.addLine(to: CGPoint(x: x, y: rect.maxY - 1 - Double.random(in: 0...6, using: &generator)))
            x -= 6
        }
        path.closeSubpath()
        return path
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// The thin black slot the receipt comes out of.
struct PrinterSlot: View {
    var body: some View {
        Capsule().fill(Theme.ink).frame(height: 7).padding(.horizontal, 22)
    }
}

struct Receipt<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TornPaperShape().fill(Theme.paper).shadow(color: Color(red: 0.16, green: 0.13, blue: 0.09).opacity(0.13), radius: 4, y: 3))
        .padding(.horizontal, 30)
    }
}

struct ReceiptHeader: View {
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Text(text)
                .font(.ticket(13.5, relativeTo: .footnote, medium: true))
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
            DashedRule()
        }
        .foregroundStyle(Theme.ink)
        .padding(.bottom, 4)
    }
}

struct DashedRule: View {
    var body: some View {
        Line()
            .stroke(Theme.ink.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            .frame(height: 1.5)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { $0.move(to: CGPoint(x: rect.minX, y: rect.midY)); $0.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)) }
        }
    }
}

/// Five squares, the first `value` filled: how warmth, formality and comfort print.
struct LevelSquares: View {
    let value: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { level in
                Rectangle()
                    .fill(level <= value ? Theme.ink : Color.clear)
                    .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5))
                    .frame(width: 13, height: 13)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The hand-drawn stamp-ink oval around the line that needs an answer.
struct StampRing: View {
    var body: some View {
        Image.bundled("stamp-ring")
            .resizable()
            .padding(.horizontal, -14)
            .padding(.vertical, -10)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// One printed receipt line: name, dotted leader, value.
struct ReceiptLine<Value: View>: View {
    let name: String
    var isActive = false
    @ViewBuilder var value: Value

    var body: some View {
        HStack(spacing: 0) {
            Text(name)
                .fixedSize()
                .overlay { if isActive { StampRing() } }
                .frame(width: 92, alignment: .leading)
            DottedLeader()
                .frame(width: 50, height: 3)
                .offset(y: 5)
                .padding(.trailing, 8)
                .accessibilityHidden(true)
            value
                .padding(.leading, 7)
            Spacer(minLength: 0)
        }
        .font(.ticket(15.5))
        .foregroundStyle(Theme.ink)
        .frame(minHeight: 37)
    }
}

struct BlankValue: View {
    var body: some View {
        Text("_ _ _ _")
            .tracking(1.5)
            .foregroundStyle(Color(hex: 0x8C877F))
    }
}

/// The dotted line between a receipt line's name and its value.
struct DottedLeader: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 1.5, y: proxy.size.height / 2))
                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
            }
            .stroke(Theme.ink, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [0, 7.5]))
        }
    }
}
