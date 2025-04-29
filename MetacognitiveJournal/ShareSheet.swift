import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIActivityViewController to enable sharing content
struct CustomShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = completionWithItemsHandler
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

/// Extension to support quick sharing of text content
extension View {
    func shareSheet(isPresented: Binding<Bool>, content: String, onCompletion: ((Bool) -> Void)? = nil) -> some View {
        sheet(isPresented: isPresented) {
            CustomShareSheet(
                activityItems: [content],
                completionWithItemsHandler: { (activityType, completed, items, error) in
                    if let onCompletion = onCompletion {
                        onCompletion(completed)
                    }
                }
            )
        }
    }
    
    func shareSheet(isPresented: Binding<Bool>, items: [Any], onCompletion: ((Bool) -> Void)? = nil) -> some View {
        sheet(isPresented: isPresented) {
            CustomShareSheet(
                activityItems: items,
                completionWithItemsHandler: { (activityType, completed, items, error) in
                    if let onCompletion = onCompletion {
                        onCompletion(completed)
                    }
                }
            )
        }
    }
}
