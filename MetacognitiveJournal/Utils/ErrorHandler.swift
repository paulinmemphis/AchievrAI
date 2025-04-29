import SwiftUI
import Combine


// MARK: - Error Types
// AppError is now defined in MetacognitiveJournalApp.swift. Remove this duplicate definition and use the canonical AppError everywhere.
// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    
    private var errorCancellable: AnyCancellable?
    
    private init() {
        errorCancellable = $currentError
            .map { $0 != nil }
            .assign(to: \.showingError, on: self)
    }
    
    func handle(_ error: Error, type: ((String) -> AppError)? = nil) {
        // Determine the AppError to handle
        let effectiveType = type ?? { errorMessage -> AppError in AppError.internalError(message: errorMessage) }
        
        if let appError = error as? AppError {
            currentError = appError
        } else {
            let errorMessage = error.localizedDescription // Initialize only when needed
            currentError = effectiveType(errorMessage) // Use the resolved type
        }
        
        // Log the finalized error message
        // Note: currentError should always be non-nil here if handle() is called
        print("[ERROR] Handled: \(currentError?.localizedDescription ?? "Unknown error state")")
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.dismiss()
        }
    }
    
    func dismiss() {
        currentError = nil
    }
}

// MARK: - Error Banner View
struct ErrorBannerView: View {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    var body: some View {
        if let error = errorHandler.currentError {
            VStack {
                HStack {
                    Image(systemName: error.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                    
                    Text(error.message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        errorHandler.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.9))
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                
                Spacer()
            }
            .zIndex(999) // Ensure it appears above all other content
        }
    }
}

// MARK: - View Extension for Error Handling
extension View {
    func withErrorHandling() -> some View {
        ZStack {
            self
            
            ErrorBannerView()
        }
    }
}
