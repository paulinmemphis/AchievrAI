import SwiftUI

struct PermissionRationaleView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why We Ask for Permissions")
                .font(.title2)
                .fontWeight(.bold)
            Text("- Notifications: To remind you to journal and celebrate your achievements.\n- Microphone: To enable voice journaling and transcription.\n\nWe never access your data or device features without your explicit action.")
                .font(.body)
            Spacer()
        }
        .padding()
        .navigationTitle("Permissions")
    }
}
