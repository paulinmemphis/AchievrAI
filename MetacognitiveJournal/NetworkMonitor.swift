import Foundation
import Network
import Combine

/// Monitors network connectivity status
class NetworkMonitor: ObservableObject {
    /// Shared instance
    static let shared = NetworkMonitor()
    
    /// Whether the device is connected to the internet
    @Published var isConnected = false
    
    /// Specific network path status
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    /// Types of network connections
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    /// The network path monitor
    private let monitor = NWPathMonitor()
    
    /// The dispatch queue to run the monitor on
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// Private initializer for singleton
    private init() {
        startMonitoring()
    }
    
    /// Starts monitoring network changes
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network changes
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Updates the connection type based on the network path
    /// - Parameter path: The network path to check
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
}
