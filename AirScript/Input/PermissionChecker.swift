import AppKit
import AVFoundation
import os

enum PermissionChecker {
    private static let logger = Logger.general

    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    static var isInputMonitoringGranted: Bool {
        CGPreflightListenEventAccess()
    }

    static func checkMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        default:
            return false
        }
    }

    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    static func openInputMonitoringSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }

    static func openMicrophoneSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
    }

    static func requestAccessibilityIfNeeded() {
        if !isAccessibilityGranted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    static func requestInputMonitoringIfNeeded() {
        if !isInputMonitoringGranted {
            CGRequestListenEventAccess()
        }
    }
}
