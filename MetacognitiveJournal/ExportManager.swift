import Foundation
import SwiftUI
import UIKit

class ExportManager {
    static func exportEntryAsText(_ entry: JournalEntry) -> String {
        "Assignment: \(entry.assignmentName)\nDate: \(entry.date)\nSubject: \(entry.subject.rawValue)\nReflection: \(entry.reflectionPrompts.map { $0.response ?? "" }.joined(separator: "\n"))"
    }
    // Generate branded security/privacy PDF
    static func generateSecurityPrivacyPDF() -> URL? {
        let pdfFileName = "SecurityPrivacySummary.pdf"
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let pdfURL = docDir.appendingPathComponent(pdfFileName)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        do {
            try renderer.writePDF(to: pdfURL) { ctx in
                ctx.beginPage()
                // Draw app icon at the top center
                if let appIcon = UIImage(systemName: "brain.head.profile")?.withRenderingMode(.alwaysTemplate) {
                    let tintedIcon = appIcon.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
                    let imgRect = CGRect(x: 256, y: 40, width: 100, height: 100)
                    tintedIcon.draw(in: imgRect)
                }
                // Title
                let title = "Security & Privacy Policy"
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 28),
                    .foregroundColor: UIColor.label
                ]
                title.draw(at: CGPoint(x: 60, y: 260), withAttributes: titleAttrs)
                // Body
                let body = """
Last updated: 2025-04-24

App Name: Metacognitive Journal

1. Data Encryption & Storage
All journal entries are encrypted on your device using AES-GCM encryption. Data is stored locally, never sent to a server unless you explicitly export or use AI features (with opt-in).

2. App Lock & Authentication
You can enable Face ID or Touch ID to protect your journal from unauthorized access. App Lock can be toggled in settings.

3. Permission Transparency
Notifications are used for reminders. Microphone access is used for voice journaling. We only request permissions with clear in-app explanations.

4. Export & Sharing Warnings
Before exporting or sharing entries, you are warned about sharing sensitive information. Parental consent is required for minors.

5. Parental Controls & Consent
Parents can review entries and receive alerts for concerning content. No data is shared without explicit consent.

6. No Hidden Data Collection
No personal data is sent to external servers unless you opt in to AI features. We do not sell or share your data.

7. User Rights & Support
You can export or delete your data at any time. Contact support for privacy questions or data removal requests.
"""
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.label
                ]
                let bodyRect = CGRect(x: 60, y: 300, width: 492, height: 440)
                body.draw(in: bodyRect, withAttributes: bodyAttrs)
            }
            return pdfURL
        } catch {
            print("[ExportManager] Failed to generate PDF: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
