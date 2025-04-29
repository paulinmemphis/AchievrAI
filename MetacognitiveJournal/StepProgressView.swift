import SwiftUI

/// A view that displays progress through a multi-step process
struct StepProgressView: View {
    // MARK: - Properties
    @EnvironmentObject private var themeManager: ThemeManager
    var currentStep: GuidedMultiModalJournalViewModel.JournalStep
    
    // MARK: - Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(GuidedMultiModalJournalViewModel.JournalStep.allCases, id: \.self) { step in
                    stepView(for: step)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Step View
    private func stepView(for step: GuidedMultiModalJournalViewModel.JournalStep) -> some View {
        let isActive = step == currentStep
        let isPast = step.rawValue < currentStep.rawValue
        let isFuture = step.rawValue > currentStep.rawValue
        
        return VStack(spacing: 8) {
            // Step circle with icon
            ZStack {
                Circle()
                    .fill(backgroundColor(for: isActive, isPast, isFuture))
                    .frame(width: 40, height: 40)
                
                Image(systemName: step.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor(for: isActive, isPast, isFuture))
            }
            
            // Step label
            Text(step.title)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .foregroundColor(textColor(for: isActive, isPast, isFuture))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 80)
        }
        .padding(.horizontal, 4)
        .opacity(isFuture ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Methods
    private func backgroundColor(for isActive: Bool, _ isPast: Bool, _ isFuture: Bool) -> Color {
        if isActive {
            return themeManager.selectedTheme.accentColor
        } else if isPast {
            return themeManager.selectedTheme.accentColor.opacity(0.3)
        } else {
            return Color(.systemGray5)
        }
    }
    
    private func iconColor(for isActive: Bool, _ isPast: Bool, _ isFuture: Bool) -> Color {
        if isActive {
            return .white
        } else if isPast {
            return .white
        } else {
            return themeManager.selectedTheme.secondaryTextColor
        }
    }
    
    private func textColor(for isActive: Bool, _ isPast: Bool, _ isFuture: Bool) -> Color {
        if isActive {
            return themeManager.selectedTheme.primaryTextColor
        } else if isPast {
            return themeManager.selectedTheme.primaryTextColor.opacity(0.7)
        } else {
            return themeManager.selectedTheme.secondaryTextColor
        }
    }
}
