import SwiftUI
import QuickdressCore

/// The add sheet: choose the camera or the library, and the two camera permission steps.
struct AddItemSheet: View {
    @Bindable var flow: AddItemFlow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch flow.sheetStep {
            case .chooseSource: chooseSource
            case .cameraNote: cameraNote
            case .cameraOff: cameraOff
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.ground)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.ground)
        .presentationCornerRadius(22)
    }

    private var chooseSource: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Check in a piece")
                    .font(.statement(31))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.body)
                    .foregroundStyle(Theme.secondaryInk)
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 18)

            ForEach(flow.sources, id: \.id) { source in
                SourceTicket(source: source) { flow.choose(source) }
            }

            Text("Photos stay on this phone. Nothing is uploaded.")
                .font(.ticket(12.5, relativeTo: .footnote))
                .foregroundStyle(Theme.secondaryInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 6)
        }
    }

    private var cameraNote: some View {
        PermissionPage(
            icon: "camera",
            iconFill: QuickdressCore.Category.outerwear.tagColour,
            crossed: false,
            title: "Quickdress needs your camera",
            text: "You photograph each piece once. The photo is saved on this phone and is never uploaded.",
            note: "iPhone will ask you to allow it next.",
            primary: ("Continue", { flow.continueAfterNote() }),
            secondary: ("Not now", { flow.backToSources() })
        )
    }

    private var cameraOff: some View {
        PermissionPage(
            icon: "camera",
            iconFill: Theme.buttonOff,
            crossed: true,
            title: "The camera is off",
            text: "Quickdress can't use the camera. Turn it on in Settings, or check in a photo you already have.",
            note: nil,
            primary: flow.librarySource.map { source in ("Choose from library", { flow.choose(source) }) },
            secondary: ("Open Settings", { flow.openSettings() })
        )
    }
}

private struct SourceTicket: View {
    let source: any ImageSource
    let action: () -> Void

    private var isCamera: Bool { source.id == "capture.camera" }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 1.5)
                    .overlay(
                        Rectangle().stroke(Color(hex: 0xBDB8AE), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    )
                    .padding(.vertical, 8)
                    .padding(.leading, 22)
                Image(systemName: isCamera ? "camera" : "photo")
                    .font(.system(size: 24))
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.title)
                        .font(.statement(25, relativeTo: .title3))
                    Text(isCamera ? "Lay it flat, in daylight" : "Use a photo you already took")
                        .font(.ticket(12.5, relativeTo: .footnote))
                        .foregroundStyle(Theme.secondaryInk)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.secondaryInk)
                    .padding(.trailing, 18)
            }
            .foregroundStyle(Theme.ink)
            .frame(minHeight: 78)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.paper).shadow(color: .black.opacity(0.10), radius: 2, y: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

private struct PermissionPage: View {
    let icon: String
    let iconFill: Color
    let crossed: Bool
    let title: LocalizedStringKey
    let text: LocalizedStringKey
    let note: LocalizedStringKey?
    let primary: (LocalizedStringKey, () -> Void)?
    let secondary: (LocalizedStringKey, () -> Void)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Image(systemName: icon + ".fill").font(.system(size: 38)).foregroundStyle(iconFill)
                Image(systemName: icon).font(.system(size: 38)).foregroundStyle(Theme.ink)
                if crossed {
                    Rectangle().fill(Theme.stamp).frame(width: 52, height: 3).rotationEffect(.degrees(40))
                }
            }
            .frame(width: 56, height: 48)
            .accessibilityHidden(true)
            .padding(.top, 30)
            Text(title)
                .font(.statement(31))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .font(.body)
                .foregroundStyle(Theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            if let note {
                Text(note)
                    .font(.ticket(12.5, relativeTo: .footnote))
                    .foregroundStyle(Theme.secondaryInk)
                    .padding(.top, 12)
            }
            Spacer(minLength: 16)
            VStack(spacing: 10) {
                if let primary {
                    Button(primary.0, action: primary.1)
                        .buttonStyle(StubButtonStyle())
                        .padding(.horizontal, -16)
                }
                Button(secondary.0, action: secondary.1)
                    .buttonStyle(UnderlinedButtonStyle())
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
    }
}
