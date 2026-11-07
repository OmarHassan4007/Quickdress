import SwiftUI
import UIKit
import Observation
import QuickdressCore

/// Runs the add-item flow: choose a source, handle camera permission, take or pick a photo,
/// then hand it to the check-in screen (FR-01, NFR-07). See Design/Add item interface, section 2.
@MainActor
@Observable
final class AddItemFlow {
    enum SheetStep: Equatable {
        case chooseSource
        case cameraNote
        case cameraOff
    }

    var isSheetPresented = false
    var sheetStep = SheetStep.chooseSource
    var checkIn: CheckInViewModel?
    var errorMessage: String?

    /// Image sources that work on this device, the camera first.
    let sources: [any ImageSource]
    @ObservationIgnored private let manager: WardrobeManager
    @ObservationIgnored private var lastSource: (any ImageSource)?
    @ObservationIgnored private var pendingPhoto: Data?
    @ObservationIgnored private var pendingSource: (any ImageSource)?

    init(sources: [any ImageSource], manager: WardrobeManager) {
        self.sources = sources.filter(\.isAvailable).sorted { $0.priority > $1.priority }
        self.manager = manager
    }

    var librarySource: (any ImageSource)? {
        sources.first { $0.access == .granted && $0.id != pendingSource?.id }
    }

    func start() {
        sheetStep = .chooseSource
        isSheetPresented = true
    }

    func choose(_ source: any ImageSource) {
        pendingSource = source
        switch source.access {
        case .granted:
            Task { await capture(with: source) }
        case .notDetermined:
            withAnimation(.snappy) { sheetStep = .cameraNote }
        case .denied:
            withAnimation(.snappy) { sheetStep = .cameraOff }
        }
    }

    /// "Continue" on the camera note: iOS shows its own permission alert next.
    func continueAfterNote() {
        guard let source = pendingSource else { return }
        Task {
            if await source.requestAccess() {
                await capture(with: source)
            } else {
                withAnimation(.snappy) { sheetStep = .cameraOff }
            }
        }
    }

    func backToSources() {
        withAnimation(.snappy) { sheetStep = .chooseSource }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func capture(with source: any ImageSource) async {
        do {
            let photo = try await source.capture()
            lastSource = source
            pendingPhoto = photo
            isSheetPresented = false
        } catch ImageSourceError.cancelled {
            // The user backed out of Apple's screen; the add sheet stays open.
        } catch ImageSourceError.accessDenied {
            withAnimation(.snappy) { sheetStep = .cameraOff }
        } catch {
            errorMessage = String(localized: "This photo can't be used. Try another photo.")
        }
    }

    /// Called when the add sheet has finished closing.
    func sheetDidDismiss() {
        guard let photo = pendingPhoto else { return }
        pendingPhoto = nil
        checkIn = makeCheckIn(photo: photo)
    }

    /// "Retake": opens the same source again over the New item screen and starts over with the new photo.
    func retake() {
        guard let source = lastSource ?? sources.first else { return }
        Task {
            do {
                let photo = try await source.capture()
                checkIn = makeCheckIn(photo: photo)
            } catch ImageSourceError.cancelled {
                // Keep the current photo and answers.
            } catch {
                errorMessage = String(localized: "This photo can't be used. Try another photo.")
            }
        }
    }

    func finish() {
        checkIn = nil
    }

    private func makeCheckIn(photo: Data) -> CheckInViewModel {
        let model = CheckInViewModel(photo: photo, manager: manager)
        model.start()
        return model
    }
}
