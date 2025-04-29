import SwiftUI

struct AppLockSettingsView: View {
    @ObservedObject var appLock: AppLockManager
    @AppStorage("appLockEnabled") private var appLockEnabled: Bool = false
    var body: some View {
        NavigationView {
            Form {
                Toggle("Enable App Lock (Face ID / Touch ID)", isOn: $appLockEnabled)
                    .onChange(of: appLockEnabled) { 
                        appLock.showLockScreen = appLockEnabled
                    }
                if appLockEnabled {
                    Button("Lock Now") {
                        appLock.showLockScreen = true
                    }
                }
            }
            .navigationTitle("App Lock Settings")
        }
    }
}

struct AppLockSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppLockSettingsView(appLock: AppLockManager())
    }
}
