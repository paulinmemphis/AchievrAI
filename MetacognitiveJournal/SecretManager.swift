import Foundation
import Security

/// Manages sensitive API keys and credentials for the application
class SecretManager {
    static let shared = SecretManager()
    
    // Key constants
    private enum SecretKeys: String {
        case openAiKey = "com.achievrai.openai.apikey"
    }
    
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    /// Save OpenAI API key securely in the keychain
    func saveOpenAIKey(_ apiKey: String) -> Bool {
        return saveSecret(apiKey, for: .openAiKey)
    }
    
    /// Retrieve OpenAI API key from the keychain
    func getOpenAIKey() -> String? {
        return getSecret(for: .openAiKey)
    }
    
    /// Delete OpenAI API key from the keychain
    func deleteOpenAIKey() -> Bool {
        return deleteSecret(for: .openAiKey)
    }
    
    // MARK: - Private Keychain Methods
    
    private func saveSecret(_ secret: String, for key: SecretKeys) -> Bool {
        // Delete any existing key first
        _ = deleteSecret(for: key)
        
        let secretData = secret.data(using: .utf8)!
        
        // Create query for keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: secretData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Add to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getSecret(for key: SecretKeys) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let secret = String(data: data, encoding: .utf8) {
            return secret
        } else {
            // For development only - check environment variable or return a default key
            #if DEBUG
            if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
                return envKey
            }
            #endif
            return nil
        }
    }
    
    private func deleteSecret(for key: SecretKeys) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - API Key Management View
import SwiftUI

struct APIKeyManagementView: View {
    @State private var apiKey = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isKeyStored = false
    
    private let secretManager = SecretManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key")) {
                if isKeyStored {
                    HStack {
                        Text("API Key is securely stored")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    TextField("Enter your OpenAI API key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            
            Section {
                Button(action: {
                    if isKeyStored {
                        // Delete key
                        if secretManager.deleteOpenAIKey() {
                            isKeyStored = false
                            apiKey = ""
                            alertMessage = "API key deleted successfully"
                        } else {
                            alertMessage = "Failed to delete API key"
                        }
                        showingAlert = true
                    } else {
                        // Save key
                        guard !apiKey.isEmpty else {
                            alertMessage = "Please enter a valid API key"
                            showingAlert = true
                            return
                        }
                        
                        if secretManager.saveOpenAIKey(apiKey) {
                            isKeyStored = true
                            alertMessage = "API key saved successfully"
                        } else {
                            alertMessage = "Failed to save API key"
                        }
                        showingAlert = true
                    }
                }) {
                    Text(isKeyStored ? "Remove API Key" : "Save API Key")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .foregroundColor(isKeyStored ? .red : .blue)
            }
            
            Section(header: Text("Information"), footer: Text("Your API key is stored securely in the iOS Keychain and is never shared with any third parties.")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("API Key Usage:")
                        .font(.headline)
                    
                    Text("• The OpenAI API key is used to generate narrative content in your journal entries")
                    Text("• You can get an API key from OpenAI's website")
                    Text("• Standard OpenAI API usage rates apply")
                    
                    Link("Get an OpenAI API Key", destination: URL(string: "https://platform.openai.com/account/api-keys")!)
                        .font(.headline)
                        .padding(.top, 10)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("API Configuration")
        .onAppear {
            // Check if key is already stored
            isKeyStored = secretManager.getOpenAIKey() != nil
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("API Key"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
