//
//  WeeklyInsightsBannerModifier.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//
// File: WeeklyInsightsBannerModifier.swift
import SwiftUI

struct WeeklyInsightsBannerModifier: ViewModifier {
    @State private var showBanner = false
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content.onAppear(perform: scheduleBanner)
            if showBanner { WeeklyBanner().transition(.move(edge: .top).combined(with: .opacity)) }
        }
    }
    private func scheduleBanner() { let weekday = Calendar.current.component(.weekday, from: Date()); let key = "weeklyBannerShown"
        if weekday == 1 && !UserDefaults.standard.bool(forKey: key) { showBanner = true; UserDefaults.standard.set(true, forKey: key); DispatchQueue.main.asyncAfter(deadline: .now()+5) { showBanner = false } } else if weekday == 2 { UserDefaults.standard.set(false, forKey: key) } }
}
