//
//  PerformanceMonitor.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import Foundation
import QuartzCore

// MARK: - Performance Monitoring

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private init() {}
    
    func startMeasuring(for operation: String) -> CFTimeInterval {
        return CACurrentMediaTime()
    }
    
    func stopMeasuring(startTime: CFTimeInterval, for operation: String) {
        let elapsedTime = CACurrentMediaTime() - startTime
        #if DEBUG
        print("⏱ Performance: \(operation) took \(elapsedTime * 1000) ms")
        #endif
    }
}