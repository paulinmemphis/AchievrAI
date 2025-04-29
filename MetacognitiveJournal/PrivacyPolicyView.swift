import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Your data is stored securely on your device and is never shared without your explicit consent. You may export or delete your data at any time. For minors, parental consent is required for sharing or exporting entries. No personal data is sent to external servers unless you use AI features, in which case you will be notified and must opt in.")
                Text("Permissions")
                    .font(.headline)
                Text("We request access to notifications (for reminders) and the microphone (for voice journaling). These are only used to enhance your journaling experience and are never used without your knowledge.")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
