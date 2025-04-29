import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var tempName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    TextField("Your name", text: $tempName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .accessibilityLabel("Your name")
                }
            }
            .navigationTitle("Profile Settings")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    userProfile.name = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                    presentationMode.wrappedValue.dismiss()
                }.disabled(tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
        .onAppear { tempName = userProfile.name }
    }
}

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView().environmentObject(UserProfile())
    }
}
