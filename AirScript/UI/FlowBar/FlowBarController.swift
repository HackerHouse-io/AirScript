import AppKit
import SwiftUI
import os

final class FlowBarController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<FlowBarView>?
    private let logger = Logger.ui

    var state: FlowBarState = .idle {
        didSet { updateView() }
    }
    var audioLevel: Float = 0 {
        didSet { updateView() }
    }
    var duration: TimeInterval = 0 {
        didSet { updateView() }
    }
    var partialTranscript: String = "" {
        didSet { updateView() }
    }

    func setup() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true

        let flowBarView = FlowBarView(
            state: .idle,
            audioLevel: 0,
            duration: 0,
            partialTranscript: ""
        )
        let hostingView = NSHostingView(rootView: flowBarView)
        panel.contentView = hostingView

        self.panel = panel
        self.hostingView = hostingView

        positionAtBottomCenter()
        logger.info("Flow Bar initialized")
    }

    func show() {
        panel?.orderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
        state = .idle
        partialTranscript = ""
        duration = 0
    }

    private func updateView() {
        hostingView?.rootView = FlowBarView(
            state: state,
            audioLevel: audioLevel,
            duration: duration,
            partialTranscript: partialTranscript
        )
    }

    private func positionAtBottomCenter() {
        guard let screen = NSScreen.main, let panel else { return }
        let x = screen.frame.midX - panel.frame.width / 2
        let y = screen.visibleFrame.minY + 60
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
