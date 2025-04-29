import Foundation
import SwiftUI

/// Manages server configuration settings for API endpoints
class ServerConfig: ObservableObject {
    @Published var serverURL: URL {
        didSet {
            UserDefaults.standard.set(serverURL.absoluteString, forKey: "narrativeServerURL")
        }
    }
    
    @Published var isEditingURL = false
    @Published var tempURLString: String = ""
    
    static let shared = ServerConfig()
    
    init() {
        // Load from UserDefaults or use default
        if let savedURLString = UserDefaults.standard.string(forKey: "narrativeServerURL"),
           let url = URL(string: savedURLString) {
            self.serverURL = url
        } else {
            // Default to localhost for simulator, can be changed in settings
            #if targetEnvironment(simulator)
            self.serverURL = URL(string: "http://localhost:3000")!
            #else
            // For physical devices, try to use a reasonable default
            // This should be changed by the user in settings
            self.serverURL = URL(string: "http://192.168.1.1:3000")!
            #endif
            
            // Save default to UserDefaults
            UserDefaults.standard.set(serverURL.absoluteString, forKey: "narrativeServerURL")
        }
        
        self.tempURLString = serverURL.absoluteString
    }
    
    func validateAndUpdateURL() -> Bool {
        guard let url = URL(string: tempURLString) else {
            return false
        }
        
        // Simple validation - could be more sophisticated
        guard url.scheme == "http" || url.scheme == "https" else {
            return false
        }
        
        serverURL = url
        isEditingURL = false
        return true
    }
}

/// A view for configuring the server URL
struct ServerConfigView: View {
    @ObservedObject var config = ServerConfig.shared
    @State private var showingValidationAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Server Configuration"), footer: Text("Enter the URL of your narrative engine server. Example: http://192.168.1.100:3000")) {
                if config.isEditingURL {
                    TextField("Server URL", text: $config.tempURLString)
                        .keyboardType(.URL)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    Button("Save") {
                        if !config.validateAndUpdateURL() {
                            showingValidationAlert = true
                        }
                    }
                } else {
                    HStack {
                        Text(config.serverURL.absoluteString)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Edit") {
                            config.isEditingURL = true
                        }
                    }
                }
            }
            
            Section(header: Text("Connection Test")) {
                Button("Test Connection") {
                    // Implement a simple test connection to the server
                    testServerConnection()
                }
            }
        }
        .navigationTitle("Server Settings")
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Invalid URL"),
                message: Text("Please enter a valid URL with http:// or https:// prefix"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func testServerConnection() {
        // Create a simple GET request to the server's root endpoint
        let url = config.serverURL
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Handle connection error
                    print("Connection error: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    // Check status code
                    if httpResponse.statusCode == 200 {
                        print("Connection successful!")
                    } else {
                        print("Connection failed with status code: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
}
