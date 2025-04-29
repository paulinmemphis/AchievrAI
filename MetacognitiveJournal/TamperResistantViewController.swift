//
//  TamperResistantViewController.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/17/25.
//


import UIKit

class TamperResistantViewController: UIViewController {
    private var originalViewHierarchyHash: String?
    private var isMonitoringActive = true
    private var monitoringTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Capture the original view hierarchy after setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.originalViewHierarchyHash = self.hashViewHierarchy(self.view)
            self.startViewHierarchyMonitoring()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopViewHierarchyMonitoring()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Re-calculate view hierarchy hash
        if originalViewHierarchyHash != nil {
            let currentHash = hashViewHierarchy(view)
            if currentHash != originalViewHierarchyHash {
                // View hierarchy has changed unexpectedly
                handleTamperingDetected()
            } else {
                startViewHierarchyMonitoring()
            }
        } else {
            // First appearance, capture the original hash
            originalViewHierarchyHash = hashViewHierarchy(view)
            startViewHierarchyMonitoring()
        }
    }
    
    // Calculate a hash of the view hierarchy
    private func hashViewHierarchy(_ view: UIView) -> String {
        var description = view.description
        
        // Add key properties to the description
        description += "frame:\(view.frame),hidden:\(view.isHidden),alpha:\(view.alpha)"
        
        // Add subviews recursively
        for subview in view.subviews {
            description += hashViewHierarchy(subview)
        }
        
        // Generate SHA-256 hash of the description
        if let data = description.data(using: .utf8) {
            return AppIntegrityValidator.generateSHA256(data: data)
        }
        
        return ""
    }
    
    // Start periodic monitoring
    private func startViewHierarchyMonitoring() {
        guard isMonitoringActive, monitoringTimer == nil else {
            return
        }
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, let originalHash = self.originalViewHierarchyHash else {
                return
            }
            
            let currentHash = self.hashViewHierarchy(self.view)
            if currentHash != originalHash {
                self.handleTamperingDetected()
            }
        }
    }
    
    // Stop monitoring
    private func stopViewHierarchyMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // Handle detected tampering
    private func handleTamperingDetected() {
        // Stop monitoring to prevent multiple alerts
        isMonitoringActive = false
        stopViewHierarchyMonitoring()
        
        // Log the event
        SecureLogger.logSecurityEvent(
            event: "UI tampering detected",
            details: ["viewController": String(describing: type(of: self))]
        )
        
        // Show an alert
        let alert = UIAlertController(
            title: "UI Error",
            message: "The user interface has been modified unexpectedly. The app will restart for security reasons.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Force app restart
            exit(0)
        })
        
        present(alert, animated: true)
    }
    
    // Add this method for your critical views that need extra protection
    func protectView(_ view: UIView) {
        // Disable user interaction inspector (helps prevent runtime manipulation)
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if String(describing: type(of: recognizer)).contains("DebugGesture") {
                    view.removeGestureRecognizer(recognizer)
                }
            }
        }
        
        // Add tampering detection
        let originalBackgroundColor = view.backgroundColor
        
        view.layer.addObserver(self, forKeyPath: "backgroundColor", options: .new, context: nil)
        view.layer.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
        view.layer.addObserver(self, forKeyPath: "hidden", options: .new, context: nil)
        
        // Store the original value for later verification
        objc_setAssociatedObject(view, "originalBackgroundColor", originalBackgroundColor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let layer = object as? CALayer, keyPath == "backgroundColor" {
            if let view = layer.delegate as? UIView {
                let originalColor = objc_getAssociatedObject(view, "originalBackgroundColor") as? UIColor
                let currentColor = view.backgroundColor
                
                if originalColor != nil && currentColor != originalColor {
                    // Background color changed unexpectedly
                    handleTamperingDetected()
                }
            }
        } else if keyPath == "bounds" || keyPath == "hidden" {
            // View bounds or visibility changed unexpectedly
            handleTamperingDetected()
        }
    }
}

// Usage example - Secure login view controller
class SecureLoginViewController: TamperResistantViewController {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply extra protection to sensitive UI elements
        protectView(usernameField)
        protectView(passwordField)
        protectView(loginButton)
    }
}