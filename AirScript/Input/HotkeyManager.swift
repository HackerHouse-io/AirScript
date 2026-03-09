import Cocoa
import os

final class HotkeyManager {
    var onPushToTalkStart: (() -> Void)?
    var onPushToTalkEnd: (() -> Void)?
    var onHandsFreeToggle: (() -> Void)?
    var onCancel: (() -> Void)?
    var onCommandModeStart: (() -> Void)?
    var onCommandModeEnd: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isFnHeld = false
    private var isCommandMode = false
    private var lastFnReleaseTime: Date?
    private var isHandsFreeActive = false
    private let doubleTapInterval = Constants.Defaults.doubleTapInterval

    /// Short delay before starting push-to-talk, to allow fn+Ctrl to be detected as command mode
    private var pttDelayTask: DispatchWorkItem?
    private let pttDelay: TimeInterval = 0.15

    private let logger = Logger.hotkey

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }

        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
            return manager.handleEvent(proxy: proxy, type: type, event: event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: selfPtr
        ) else {
            logger.error("Failed to create event tap. Check Input Monitoring permission.")
            return false
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        logger.info("Hotkey manager started")
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
        pttDelayTask?.cancel()
        pttDelayTask = nil
        logger.info("Hotkey manager stopped")
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // Handle tap being disabled by system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // Handle Escape key to cancel
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == 0x35 { // Escape
                if isFnHeld || isHandsFreeActive {
                    logger.debug("Cancel via Escape")
                    isFnHeld = false
                    isCommandMode = false
                    isHandsFreeActive = false
                    pttDelayTask?.cancel()
                    pttDelayTask = nil
                    onCancel?()
                    return nil // swallow the event
                }
            }
            return Unmanaged.passUnretained(event)
        }

        // Handle fn key via flagsChanged
        if type == .flagsChanged {
            let flags = event.flags
            let fnPressed = flags.contains(.maskSecondaryFn)
            let ctrlPressed = flags.contains(.maskControl)

            if fnPressed && !isFnHeld {
                // fn pressed down
                isFnHeld = true

                // Check for double-tap
                if let lastRelease = lastFnReleaseTime,
                   Date().timeIntervalSince(lastRelease) < doubleTapInterval {
                    // Double-tap: toggle hands-free
                    lastFnReleaseTime = nil
                    isHandsFreeActive.toggle()
                    logger.debug("Hands-free toggled: \(self.isHandsFreeActive)")
                    onHandsFreeToggle?()
                } else if ctrlPressed {
                    // fn+Ctrl pressed together — command mode immediately
                    isCommandMode = true
                    logger.debug("Command mode activated")
                    onCommandModeStart?()
                } else {
                    // Defer push-to-talk start to allow Ctrl to arrive
                    let task = DispatchWorkItem { [weak self] in
                        guard let self, self.isFnHeld, !self.isCommandMode else { return }
                        self.logger.debug("Push-to-talk started")
                        self.onPushToTalkStart?()
                    }
                    pttDelayTask = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + pttDelay, execute: task)
                }
            } else if fnPressed && isFnHeld && ctrlPressed && !isCommandMode {
                // Ctrl pressed while fn already held — upgrade to command mode
                pttDelayTask?.cancel()
                pttDelayTask = nil
                isCommandMode = true
                logger.debug("Command mode activated (upgraded from PTT)")
                // Cancel any in-progress PTT and switch to command mode
                onCancel?()
                onCommandModeStart?()
            } else if !fnPressed && isFnHeld {
                // fn released
                isFnHeld = false
                pttDelayTask?.cancel()
                pttDelayTask = nil
                lastFnReleaseTime = Date()

                if isCommandMode {
                    isCommandMode = false
                    logger.debug("Command mode ended")
                    onCommandModeEnd?()
                } else if !isHandsFreeActive {
                    logger.debug("Push-to-talk ended")
                    onPushToTalkEnd?()
                }
            }
        }

        return Unmanaged.passUnretained(event)
    }

    deinit {
        stop()
    }
}
