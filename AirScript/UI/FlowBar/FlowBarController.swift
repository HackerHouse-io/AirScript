import AppKit
import SwiftUI
import os

final class FlowBarController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<FlowBarView>?
    private let logger = Logger.ui

    var state: FlowBarState = .idle {
        didSet {
            updateView()
            if oldValue != state, panel?.isVisible == true { resizePanelToFit() }
        }
    }
    var audioLevel: Float = 0
    var duration: TimeInterval = 0 {
        didSet { updateView() }
    }
    var partialTranscript: String = "" {
        didSet {
            updateView()
            if oldValue.isEmpty != partialTranscript.isEmpty, panel?.isVisible == true { resizePanelToFit() }
        }
    }

    func setup() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 56, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
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

        let size = hostingView.fittingSize
        if size.width > 0, size.height > 0 {
            panel.setContentSize(size)
        }

        positionAtRightCenter()
        logger.info("Flow Bar initialized")
    }

    func show() {
        resizePanelToFit()
        positionAtRightCenter()
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

    private func resizePanelToFit() {
        guard let hostingView, let panel else { return }
        let newSize = hostingView.fittingSize
        guard newSize.width > 0, newSize.height > 0 else { return }
        let oldFrame = panel.frame
        let newOrigin = NSPoint(
            x: oldFrame.maxX - newSize.width,
            y: oldFrame.midY - newSize.height / 2
        )
        panel.setFrame(NSRect(origin: newOrigin, size: newSize), display: true)
    }

    private func positionAtRightCenter() {
        guard let screen = NSScreen.main, let panel else { return }
        let margin = AirScriptTheme.Spacing.lg
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.maxX - panel.frame.width - margin
        let y = visibleFrame.midY - panel.frame.height / 2
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
