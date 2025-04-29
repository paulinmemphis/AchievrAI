import Foundation
import Combine
import SwiftUI

/// Manages network errors and provides offline capabilities
class NetworkErrorManager: ObservableObject {
    static let shared = NetworkErrorManager()
    
    @Published var isOffline = false
    @Published var pendingRequests: [PendingRequest] = []
    
    // Storage for offline requests
    private let pendingRequestsKey = "com.achievrai.pendingRequests"
    
    // Initialize with any saved pending requests
    private init() {
        loadPendingRequests()
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        // In a real app, use NWPathMonitor to check connectivity
        // For this implementation, we'll simulate network detection
        checkConnectivity()
    }
    
    // Simulate checking connectivity
    func checkConnectivity() {
        // In a real app, this would use NWPathMonitor
        // For now just use URLSession to try connecting to known endpoints
        let url = URL(string: "https://www.apple.com")!
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network appears to be offline: \(error.localizedDescription)")
                    self.isOffline = true
                } else if let httpResponse = response as? HTTPURLResponse {
                    self.isOffline = httpResponse.statusCode >= 400
                } else {
                    self.isOffline = false
                }
            }
        }
        task.resume()
    }
    
    // Queue a request for later when offline
    func queueRequest(_ request: PendingRequest) {
        pendingRequests.append(request)
        savePendingRequests()
    }
    
    // Try to process any pending requests
    func processPendingRequests() {
        guard !isOffline, !pendingRequests.isEmpty else { return }
        
        // Process the oldest requests first
        let request = pendingRequests.removeFirst()
        savePendingRequests()
        
        // Post a notification that can be observed by services
        NotificationCenter.default.post(
            name: .pendingRequestReady,
            object: request
        )
    }
    
    // Save pending requests to UserDefaults
    private func savePendingRequests() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(pendingRequests)
            UserDefaults.standard.set(data, forKey: pendingRequestsKey)
        } catch {
            print("Failed to save pending requests: \(error)")
        }
    }
    
    // Load pending requests from UserDefaults
    private func loadPendingRequests() {
        guard let data = UserDefaults.standard.data(forKey: pendingRequestsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            pendingRequests = try decoder.decode([PendingRequest].self, from: data)
        } catch {
            print("Failed to load pending requests: \(error)")
        }
    }
}

// Model for a pending request that can be serialized
struct PendingRequest: Codable, Identifiable {
    var id = UUID()
    let endpoint: String
    let method: String
    let body: String // JSON string of request body
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, endpoint, method, body, timestamp
    }
}

// Notification name extension
extension Notification.Name {
    static let pendingRequestReady = Notification.Name("PendingRequestReady")
}

// SwiftUI modifier for handling offline states
struct OfflineAwareModifier: ViewModifier {
    @ObservedObject var networkManager = NetworkErrorManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if networkManager.isOffline {
                VStack {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.white)
                        Text("You're offline")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .bold()
                        Spacer()
                        Button(action: {
                            networkManager.checkConnectivity()
                        }) {
                            Text("Retry")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if !networkManager.pendingRequests.isEmpty {
                        HStack {
                            Text("\(networkManager.pendingRequests.count) requests pending")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .transition(.move(edge: .top))
                .animation(.easeInOut, value: networkManager.isOffline)
            }
        }
    }
}

// Extension to add modifier to any view
extension View {
    func offlineAware() -> some View {
        self.modifier(OfflineAwareModifier())
    }
}

// AnyPublisher extension for retrying with exponential backoff
extension Publisher {
    func retry<T, E>(
        _ retries: Int,
        delay: TimeInterval = 1.0,
        scheduler: DispatchQueue = .main
    ) -> AnyPublisher<T, E> where T == Output, E == Failure {
        self.catch { error -> AnyPublisher<T, E> in
            guard retries > 0 else {
                return Fail(error: error).eraseToAnyPublisher()
            }
            
            return Just(())
                .delay(for: .seconds(delay), scheduler: scheduler)
                .flatMap { _ in
                    self.retry(retries - 1, delay: delay * 2, scheduler: scheduler)
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
