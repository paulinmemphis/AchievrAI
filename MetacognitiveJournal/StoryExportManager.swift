// StoryExportManager.swift
import Foundation
import UIKit
import PDFKit
import SwiftUI

/// Manages exporting the user's story to various formats
class StoryExportManager: ObservableObject {
    
    /// Export story nodes as plain text
    func exportAsText(from nodes: [StoryNode]) -> String {
        var storyText = "MY PERSONAL NARRATIVE\n"
        storyText += "====================\n\n"
        
        // Sort nodes chronologically
        let sortedNodes = nodes.sorted { $0.createdAt < $1.createdAt }
        
        // Build text for each chapter
        for (index, node) in sortedNodes.enumerated() {
            storyText += "CHAPTER \(index + 1)\n"
            storyText += String(repeating: "-", count: 10) + "\n\n"
            
            // Add metadata context
            storyText += "Themes: \(node.metadataSnapshot?.themes?.joined(separator: ", ") ?? "N/A")\n"
            storyText += "Mood: \(getSentimentLabel(from: node.metadataSnapshot?.sentimentScore))\n\n"
            
            // Add chapter text
            if let chapter = StoryPersistenceManager.shared.getChapter(id: node.chapterId) {
                storyText += chapter.text
            }
            storyText += "\n\n"
            
            // Add separator between chapters except for the last one
            if index < sortedNodes.count - 1 {
                storyText += "* * *\n\n"
            }
        }
        
        // Add timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        storyText += "\n\nCreated: \(dateFormatter.string(from: Date()))"
        
        return storyText
    }
    
    /// Export story nodes as PDF
    func exportAsPDF(from nodes: [StoryNode], title: String = "My Personal Story") -> Data? {
        // Create a PDF document with pages
        let pdfMetaData = [
            kCGPDFContextCreator: "Metacognitive Journal",
            kCGPDFContextAuthor: "Story Owner",
            kCGPDFContextTitle: title
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0 // US Letter width in points (72 points = 1 inch)
        let pageHeight = 11.0 * 72.0 // US Letter height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Create PDF renderer
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        // Render PDF
        let pdfData = renderer.pdfData { context in
            // Sort nodes by timestamp
            let sortedNodes = nodes.sorted { $0.createdAt < $1.createdAt }
            
            // Title page
            context.beginPage()
            drawTitlePage(in: pageRect, title: title)
            
            // Content pages - one per chapter
            for (index, node) in sortedNodes.enumerated() {
                context.beginPage()
                drawChapter(in: pageRect, node: node, chapterNumber: index + 1)
            }
        }
        
        return pdfData
    }
    
    /// Share the story using UIActivityViewController
    func shareStory(from nodes: [StoryNode], title: String = "My Personal Story", sourceView: UIView, sourceRect: CGRect?) {
        guard !nodes.isEmpty else { return }
        
        // Create text and PDF versions
        let textContent = exportAsText(from: nodes)
        guard let pdfData = exportAsPDF(from: nodes, title: title) else { return }
        
        // Create temporary files
        let textURL = createTemporaryFile(with: textContent, fileExtension: "txt")
        let pdfURL = createTemporaryFile(with: pdfData, fileExtension: "pdf")
        
        // Create activity view controller with items to share
        var itemsToShare: [Any] = [title]
        if let textURL = textURL {
            itemsToShare.append(textURL)
        }
        if let pdfURL = pdfURL {
            itemsToShare.append(pdfURL)
        }
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        // Find the key window scene to present the controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            // For iPad, set the popover presentation source
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // Present the activity view controller
            DispatchQueue.main.async {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    private func getSentimentLabel(from score: Double?) -> String {
        guard let s = score else { return "Neutral" } // Default if score is nil
        if s > 0.25 { return "Positive" }
        if s < -0.25 { return "Negative" }
        return "Neutral"
    }

    // MARK: - Helper Methods
    
    /// Create a temporary file for exporting
    private func createTemporaryFile(with content: Any, fileExtension: String) -> URL? {
        let fileName = "my-story.\(fileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            if content is String {
                try (content as! String).write(to: fileURL, atomically: true, encoding: .utf8)
            } else if content is Data {
                try (content as! Data).write(to: fileURL)
            } else {
                return nil
            }
            return fileURL
        } catch {
            print("Error creating temporary file: \(error)")
            return nil
        }
    }
    
    /// Draw the title page of the PDF
    private func drawTitlePage(in rect: CGRect, title: String) {
        let textRect = CGRect(x: 72, y: 72, width: rect.width - 144, height: rect.height - 144)
        
        // Draw title
        let titleFont = UIFont.systemFont(ofSize: 40, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: textRect.midX - titleSize.width / 2,
            y: textRect.midY - 100,
            width: titleSize.width,
            height: titleSize.height
        )
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Generated on \(dateFormatter.string(from: Date()))"
        
        let dateFont = UIFont.systemFont(ofSize: 14)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateSize = dateString.size(withAttributes: dateAttributes)
        let dateRect = CGRect(
            x: textRect.midX - dateSize.width / 2,
            y: textRect.midY + 80,
            width: dateSize.width,
            height: dateSize.height
        )
        
        dateString.draw(in: dateRect, withAttributes: dateAttributes)
        
        // Draw decorative elements
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(2)
        
        // Top line
        context.move(to: CGPoint(x: textRect.minX, y: textRect.minY))
        context.addLine(to: CGPoint(x: textRect.maxX, y: textRect.minY))
        
        // Bottom line
        context.move(to: CGPoint(x: textRect.minX, y: textRect.maxY))
        context.addLine(to: CGPoint(x: textRect.maxX, y: textRect.maxY))
        context.strokePath()
    }
    
    /// Draw a chapter page of the PDF
    private func drawChapter(in rect: CGRect, node: StoryNode, chapterNumber: Int) {
        let margin: CGFloat = 72 // 1 inch margin
        let textRect = CGRect(
            x: margin,
            y: margin,
            width: rect.width - 2 * margin,
            height: rect.height - 2 * margin
        )
        
        var currentY: CGFloat = textRect.minY
        
        // Chapter title
        let chapterTitle = "Chapter \(chapterNumber)"
        let titleFont = UIFont.systemFont(ofSize: 30, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = chapterTitle.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: textRect.minX, y: currentY, width: titleSize.width, height: titleSize.height)
        chapterTitle.draw(in: titleRect, withAttributes: titleAttributes)
        
        currentY += titleSize.height + 20
        
        // Metadata
        let metadataFont = UIFont.italicSystemFont(ofSize: 12)
        let metadataAttributes: [NSAttributedString.Key: Any] = [
            .font: metadataFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        // Themes
        let themesString = "Themes: \(node.metadataSnapshot?.themes?.joined(separator: ", ") ?? "N/A")"
        let themesSize = themesString.size(withAttributes: metadataAttributes)
        let themesRect = CGRect(x: textRect.minX, y: currentY, width: textRect.width, height: themesSize.height)
        themesString.draw(in: themesRect, withAttributes: metadataAttributes)
        
        currentY += themesSize.height + 10
        
        // Mood
        let moodString = "Mood: \(node.metadataSnapshot?.sentimentScore != nil ? String(describing: node.metadataSnapshot!.sentimentScore!) : "N/A")"
        let moodSize = moodString.size(withAttributes: metadataAttributes)
        let moodRect = CGRect(x: textRect.minX, y: currentY, width: textRect.width, height: moodSize.height)
        moodString.draw(in: moodRect, withAttributes: metadataAttributes)
        
        currentY += moodSize.height + 40
        
        // Draw the chapter text
        let chapterText: String = {
            if let chapter = StoryPersistenceManager.shared.getChapter(id: node.chapterId) {
                return chapter.text
            } else {
                return "[Chapter not found]"
            }
        }()
        let textFont = UIFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedText = NSAttributedString(string: chapterText, attributes: textAttributes)
        
        let textHeight = attributedText.boundingRect(
            with: CGSize(width: textRect.width, height: .greatestFiniteMagnitude),
            options: [NSStringDrawingOptions.usesLineFragmentOrigin, NSStringDrawingOptions.usesFontLeading],
            context: nil as NSStringDrawingContext?
        ).height
        
        let textDrawRect = CGRect(x: textRect.minX, y: currentY, width: textRect.width, height: textHeight)
        attributedText.draw(in: textDrawRect)
        
        currentY += textHeight + 30
        
        // Draw a page number at the bottom
        let pageNumberString = "\(chapterNumber)"
        let pageNumberFont = UIFont.systemFont(ofSize: 12)
        let pageNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: pageNumberFont,
            .foregroundColor: UIColor.gray
        ]
        
        let pageNumberSize = pageNumberString.size(withAttributes: pageNumberAttributes)
        let pageNumberRect = CGRect(
            x: textRect.midX - pageNumberSize.width / 2,
            y: textRect.maxY - pageNumberSize.height,
            width: pageNumberSize.width,
            height: pageNumberSize.height
        )
        
        pageNumberString.draw(in: pageNumberRect, withAttributes: pageNumberAttributes)
    }
}

// MARK: - SwiftUI Helper View for Export
struct StoryExportButton: View {
    let nodes: [StoryNode]
    let title: String
    
    @State private var exportManager = StoryExportManager()
    @State private var showingShareSheet = false
    @State private var sourceRect: CGRect = .zero
    
    var body: some View {
        Button(action: {
            showingShareSheet = true
        }) {
            Label("Export Story", systemImage: "square.and.arrow.up")
                .padding()
                .background(GeometryReader { geo -> Color in
                    DispatchQueue.main.async {
                        self.sourceRect = geo.frame(in: .global)
                    }
                    return Color.clear
                })
        }
        .background(StoryShareSheet(isPresented: $showingShareSheet, nodes: nodes, title: title, sourceRect: sourceRect))
    }
}

// Helper view to present UIActivityViewController
struct StoryShareSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let nodes: [StoryNode]
    let title: String
    let sourceRect: CGRect
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let manager = StoryExportManager()
            
            // Get the window scene
            // Get the current window scene and root view controller using the modern API
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let rootVC = windowScene.keyWindow?.rootViewController {
                
                // Share the story
                manager.shareStory(from: nodes, title: title, sourceView: rootVC.view, sourceRect: nil)
                
                // Reset the binding after sharing
                DispatchQueue.main.async {
                    isPresented = false
                }
            }
        }
    }
}
