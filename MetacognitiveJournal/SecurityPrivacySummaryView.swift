import SwiftUI

struct SecurityPrivacySummaryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Security & Privacy Features")
                    .font(.title2)
                    .fontWeight(.bold)
                Group {
                    Text("• **Encrypted Journals:** All journal entries are encrypted on your device using industry-standard AES-GCM encryption.")
                    Text("• **App Lock:** Enable Face ID or Touch ID to protect your journal from unauthorized access.")
                    Text("• **Local-First Data:** Your data is stored locally and never shared unless you choose to export or use AI features (with opt-in).")
                    Text("• **Permission Transparency:** The app clearly explains why notifications and microphone access are requested.")
                    Text("• **Export Warnings:** You are warned before sharing or exporting entries, to help prevent accidental sharing of sensitive information.")
                    Text("• **Parental Consent:** For minors, parental consent is required for sharing or exporting entries.")
                    Text("• **No Hidden Data Collection:** No personal data is sent to external servers without your explicit consent.")
                }
                .font(.body)
                Spacer()
                Button(action: {
                    if let url = ExportManager.generateSecurityPrivacyPDF() {
                        pdfURL = url
                        showShareSheet = true
                    }
                }) {
                    Label("Download/Share PDF", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding()
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(10)
                }
                .accessibilityLabel("Download or Share Security and Privacy PDF")
            }
            .padding()
        }
        .navigationTitle("Security & Privacy")
        .onAppear {
            pdfURL = ExportManager.generateSecurityPrivacyPDF()
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
    }
    @State private var showShareSheet = false
    @State private var pdfURL: URL? = nil
}

struct SecurityPrivacySummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityPrivacySummaryView()
    }
}
