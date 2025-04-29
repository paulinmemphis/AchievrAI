import Foundation
import LocalAuthentication

class SecureJournalStore: ObservableObject {
    @Published var entries: [JournalEntry] = []
    private let fileURL: URL
    private var encryptionPassword = ""

    init(filename: String = "journal_entries.enc", password: String) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent(filename)
        self.encryptionPassword = password
        loadEntries()
    }

    func saveEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        saveEntriesToDisk()
    }

    func saveEntriesToDisk() {
        guard !encryptionPassword.isEmpty else {
            print("[SecureJournalStore] Error: Encryption password not set.")
            return
        }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let dataToEncrypt = try encoder.encode(entries)
            guard let dataString = String(data: dataToEncrypt, encoding: .utf8) else {
                print("[SecureJournalStore] Failed to convert data to string for encryption.")
                return
            }

            if let encryptedData = EncryptionManager.encrypt(dataString, with: encryptionPassword) {
                try encryptedData.write(to: fileURL)
            } else {
                print("[SecureJournalStore] Failed to encrypt entries.")
            }
        } catch {
            print("[SecureJournalStore] Failed to save entries: \(error)")
        }
    }

    func loadEntries() {
        guard !encryptionPassword.isEmpty else {
            print("[SecureJournalStore] Error: Encryption password not set for loading.")
            entries = []
            return
        }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[SecureJournalStore] Encrypted file not found. Starting with empty journal.")
            entries = []
            return
        }

        do {
            let encryptedDataWithSalt = try Data(contentsOf: fileURL)
            if let decryptedString = EncryptionManager.decrypt(encryptedDataWithSalt, with: encryptionPassword) {
                guard let decryptedData = decryptedString.data(using: .utf8) else {
                    print("[SecureJournalStore] Failed to convert decrypted string back to data.")
                    entries = []
                    return
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                entries = try decoder.decode([JournalEntry].self, from: decryptedData)
                print("[SecureJournalStore] Successfully loaded \(entries.count) entries.")
            } else {
                print("[SecureJournalStore] Failed to decrypt entries. Check password or data corruption.")
                entries = []
            }
        } catch {
            print("[SecureJournalStore] Failed to load entries: \(error)")
            entries = []
        }
    }
}
