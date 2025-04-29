//
//  SecurityUtils.swift
//  MetacognitiveJournal
//
//  Updated to use UIWindowScene.windows instead of deprecated UIApplication.shared.windows

import UIKit
import Foundation
import MachO

class SecurityUtils {
    static func isDeviceJailbroken() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt"
        ]
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        do {
            try "JailbreakTest".write(toFile: "/private/jailbreak.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/jailbreak.txt")
            return true
        } catch {}
        return false
    }

    static func isBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    static func handleSecurityViolation() {
        let alert = UIAlertController(
            title: "Security Warning",
            message: "This app cannot run in the current environment due to security concerns.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in exit(0) })

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let viewController = window.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
}
