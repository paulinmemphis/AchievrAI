//
//  SwiftUI+Extensions.swift
//  MetacognitiveJournal
//
//  Created by Cascade on 4/27/25.
//

import SwiftUI

extension Binding where Value == String {
    /// Creates a binding that limits the length of the string.
    /// - Parameter length: The maximum number of characters allowed.
    /// - Returns: A new binding that enforces the length limit.
    func max(_ length: Int) -> Binding<String> {
        Binding<String>(
            get: {
                // Ensure the wrapped value doesn't exceed the length initially.
                // This handles cases where the underlying state might have been set beyond the limit elsewhere.
                let string = self.wrappedValue
                return String(string.prefix(length))
            },
            set: {
                // When a new value is set, truncate it if necessary before updating the original binding.
                self.wrappedValue = String($0.prefix(length))
            }
        )
    }
}
