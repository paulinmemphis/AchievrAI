import SwiftUI

/// A sheet that allows parents to set and change their child's age or birthday
struct ChildProfileSheet: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Bindings
    @Binding var birthday: Date
    @Binding var ageGroup: AgeGroup
    
    // MARK: - Properties
    var onSave: () -> Void
    
    // MARK: - State
    @State private var selectedTab = 0 // 0 for age group, 1 for birthday
    @State private var calculatedAge: Int = 0
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Selection Method", selection: $selectedTab) {
                    Text("Age Group").tag(0)
                    Text("Birthday").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 24) {
                        if selectedTab == 0 {
                            ageGroupSelector
                        } else {
                            birthdaySelector
                        }
                    }
                    .padding()
                }
            }
            .background(themeManager.selectedTheme.backgroundColor)
            .navigationTitle("Child Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
            .onAppear {
                updateCalculatedAge()
            }
        }
    }
    
    // MARK: - Views
    
    /// View for selecting age group
    private var ageGroupSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select your child's age group")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            VStack(spacing: 12) {
                ForEach([AgeGroup.child, AgeGroup.teen]) { group in
                    Button(action: {
                        ageGroup = group
                    }) {
                        HStack {
                            Text(group.displayName)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                            
                            Spacer()
                            
                            if ageGroup == group {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.selectedTheme.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ageGroup == group ? 
                                      themeManager.selectedTheme.accentColor.opacity(0.1) : 
                                      themeManager.selectedTheme.cardBackgroundColor)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Text("This setting helps personalize the app experience for your child's developmental stage.")
                .font(.caption)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .padding(.top, 8)
        }
    }
    
    /// View for selecting birthday
    private var birthdaySelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select your child's birthday")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            DatePicker(
                "Birthday",
                selection: $birthday,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .onChange(of: birthday) { _ in
                updateCalculatedAge()
                updateAgeGroupFromBirthday()
            }
            
            HStack {
                Text("Age:")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Text("\(calculatedAge) years old")
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Text("Age Group: \(ageGroup.displayName)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            Text("The app will automatically adjust content based on your child's age.")
                .font(.caption)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the age based on the selected birthday
    private func updateCalculatedAge() {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        calculatedAge = ageComponents.year ?? 0
    }
    
    /// Update the age group based on the calculated age
    private func updateAgeGroupFromBirthday() {
        if calculatedAge < 13 {
            ageGroup = .child
        } else if calculatedAge < 18 {
            ageGroup = .teen
        } else {
            ageGroup = .adult
        }
    }
}

// MARK: - Preview
struct ChildProfileSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileSheet(
            birthday: .constant(Date()),
            ageGroup: .constant(.child),
            onSave: {}
        )
        .environmentObject(ThemeManager())
    }
}
