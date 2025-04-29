import SwiftUI

struct RemindersSettingsView: View {
    @ObservedObject var reminders = RemindersManager.shared
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var message = "Time to reflect in your journal!"
    @Environment(\.presentationMode) var presentationMode
    @State private var permissionGranted = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Reminder")) {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        TextField("Message", text: $message)
                    }
                }
                if !permissionGranted {
                    Text("Enable notifications in Settings to receive reminders.")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarItems(trailing: Button("Done") {
                saveSettings()
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear(perform: loadSettings)
        }
    }

    private func loadSettings() {
        reminders.requestPermission { granted in
            permissionGranted = granted
        }
        // For demo: load from UserDefaults
        reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        let timeInterval = UserDefaults.standard.double(forKey: "reminderTime")
        if timeInterval > 0 {
            reminderTime = Date(timeIntervalSince1970: timeInterval)
        }
        message = UserDefaults.standard.string(forKey: "reminderMessage") ?? "Time to reflect in your journal!"
    }
    private func saveSettings() {
        UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
        UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: "reminderTime")
        UserDefaults.standard.set(message, forKey: "reminderMessage")
        if reminderEnabled {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: reminderTime)
            let minute = calendar.component(.minute, from: reminderTime)
            reminders.scheduleDailyReminder(at: hour, minute: minute, message: message)
        } else {
            reminders.cancelReminders()
        }
    }
}

struct RemindersSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RemindersSettingsView()
    }
}
