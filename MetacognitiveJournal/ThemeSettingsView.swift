import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Theme")) {
                    Picker("App Theme", selection: $themeManager.selectedTheme) {
    ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
        Text(theme.rawValue).tag(theme)
    }
}
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Theme Settings")
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSettingsView().environmentObject(ThemeManager())
    }
}
