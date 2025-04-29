import SwiftUI

struct ExportWarningView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            Text("Warning: Sensitive Content")
                .font(.headline)
                .foregroundColor(.orange)
            Text("You are about to export or share journal entries. Please ensure you do not share sensitive or private information unintentionally.")
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .navigationTitle("Export Warning")
    }
}
