// NarrativeReminderManager.swift
import Foundation
import UserNotifications

/// Manages local notifications to remind users to continue their narrative journey
class NarrativeReminderManager: ObservableObject {
    static let shared = NarrativeReminderManager()
    
    @Published var remindersEnabled = false
    
    private let reminderIdentifier = "narrative-reminder"
    
    init() {
        // Load saved preference
        remindersEnabled = UserDefaults.standard.bool(forKey: "narrative_reminders_enabled")
    }
    
    /// Request notification permission from the user
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.remindersEnabled = true
                    UserDefaults.standard.set(true, forKey: "narrative_reminders_enabled")
                    // Schedule reminder immediately when permission is granted
                    self.scheduleReminder()
                } else {
                    self.remindersEnabled = false
                    UserDefaults.standard.set(false, forKey: "narrative_reminders_enabled")
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    /// Schedule a reminder notification to prompt the user to continue their story
    func scheduleReminder() {
        guard remindersEnabled else { return }
        
        // Cancel any existing reminders first
        cancelReminders()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Continue Your Story"
        content.body = "Your narrative is waiting to unfold. What happens next in your journey?"
        content.sound = .default
        content.categoryIdentifier = "narrative"
        
        // Create action buttons
        let viewAction = UNNotificationAction(identifier: "VIEW_ACTION", 
                                             title: "View Story",
                                             options: .foreground)
        
        let writeAction = UNNotificationAction(identifier: "WRITE_ACTION",
                                              title: "Add Entry",
                                              options: .foreground)
        
        // Define the notification category with actions
        let category = UNNotificationCategory(identifier: "narrative",
                                             actions: [viewAction, writeAction],
                                             intentIdentifiers: [],
                                             options: [])
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        // Schedule the notification to trigger after 24h of inactivity
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 3600, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(identifier: reminderIdentifier,
                                           content: content,
                                           trigger: trigger)
        
        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error.localizedDescription)")
            } else {
                print("Narrative reminder scheduled successfully")
            }
        }
    }
    
    /// Cancel any pending narrative reminders
    func cancelReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
    
    /// Toggle reminder status and schedule/cancel reminders accordingly
    func toggleReminders() {
        remindersEnabled.toggle()
        UserDefaults.standard.set(remindersEnabled, forKey: "narrative_reminders_enabled")
        
        if remindersEnabled {
            requestNotificationPermission()
        } else {
            cancelReminders()
        }
    }
    
    /// Reset the reminder schedule after user interaction with the app
    func resetReminderSchedule() {
        guard remindersEnabled else { return }
        // Cancel existing reminders and schedule a new one
        scheduleReminder()
    }
}

// MARK: - UNUserNotificationCenterDelegate Extension
// Add this extension to handle notification responses in your app delegate or scene delegate

/*
extension YourAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Handle the notification action
        if response.notification.request.identifier == "narrative-reminder" {
            switch response.actionIdentifier {
            case "VIEW_ACTION":
                // Navigate to the StoryMapView
                // Example: YourNavigationManager.shared.navigateToStoryMap()
                break
                
            case "WRITE_ACTION":
                // Navigate to the New Entry View
                // Example: YourNavigationManager.shared.navigateToNewEntry()
                break
                
            default:
                // Default action (app opened from notification)
                break
            }
        }
        
        completionHandler()
    }
}
*/
