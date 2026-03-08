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
    private var lastFnReleaseTime: Date?
    private var isHandsFreeActive = false
    private let doubleTapInterval = Constants.Defaults.doubleTapInterval

    private let logger = Logger.hotkey

    func start() {
        guard eventTap == nil else { return }

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
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        logger.info("Hotkey manager started")
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
                    isHandsFreeActive = false
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
                } else {
                    // Single press: push-to-talk
                    logger.debug("Push-to-talk started")
                    onPushToTalkStart?()
                }
            } else if !fnPressed && isFnHeld {
                // fn released
                isFnHeld = false
                lastFnReleaseTime = Date()

                if !isHandsFreeActive {
                    logger.debug("Push-to-talk ended")
                    onPushToTalkEnd?()
                }
            }

            // Check for fn+Ctrl (command mode)
            if fnPressed && flags.contains(.maskControl) {
                logger.debug("Command mode activated")
                onCommandModeStart?()
            }
        }

        return Unmanaged.passUnretained(event)
    }

    deinit {
        stop()
    }
}
