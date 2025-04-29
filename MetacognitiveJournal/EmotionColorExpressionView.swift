import SwiftUI
import Combine

/// Extension for multi-modal emotion color expression components
extension MultiModal {
    /// A view that allows children to express emotions through colors and patterns
    struct EmotionColorExpressionView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Properties
    let journalMode: ChildJournalMode
    let onSave: (MultiModal.ColorData) -> Void
    let onCancel: () -> Void
    
    // MARK: - State
    @State private var selectedColors: [MultiModal.ColorData.ColorInfo] = [
        MultiModal.ColorData.ColorInfo(red: 1.0, green: 0.0, blue: 0.0, opacity: 0.8, meaning: nil) // Default red
    ]
    @State private var selectedPattern: MultiModal.ColorData.ColorPattern = .solid
    @State private var intensity: Int = 5
    @State private var colorDescription: String = ""
    @State private var showingColorPicker = false
    @State private var editingColorIndex: Int?
    @State private var tempColor = Color.red
    @State private var tempMeaning: String = ""
    @State private var showingGuide = false
    @State private var animateColors = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            colorHeader
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Color visualization
                    colorVisualization
                    
                    // Color controls
                    colorControls
                    
                    // Pattern selection
                    patternSelection
                    
                    // Intensity slider
                    intensitySlider
                    
                    // Description field
                    descriptionField
                }
                .padding()
            }
            
            // Footer with actions
            colorFooter
        }
        .background(themeManager.themeForChildMode(journalMode).backgroundColor)
        .sheet(isPresented: $showingColorPicker) {
            colorPickerSheet
        }
        .sheet(isPresented: $showingGuide) {
            colorGuideSheet
        }
        .onAppear {
            // Animate colors when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    animateColors = true
                }
            }
        }
    }
    
    // MARK: - Color Header
    
    private var colorHeader: some View {
        HStack {
            // Title
            Text("Color Feelings")
                .font(fontForMode(size: 18, weight: .bold))
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
            
            Spacer()
            
            // Help button
            Button(action: {
                showingGuide = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            }
        }
        .padding()
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
    }
    
    // MARK: - Color Visualization
    
    private var colorVisualization: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 2)
            
            // Color pattern visualization
            Group {
                switch selectedPattern {
                case .solid:
                    if let color = selectedColors.first {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color.color)
                    }
                    
                case .gradient:
                    if selectedColors.count >= 2 {
                        LinearGradient(
                            gradient: Gradient(colors: selectedColors.map { $0.color }),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(16)
                    } else {
                        Text("Add at least 2 colors for a gradient")
                            .font(fontForMode(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                case .radial:
                    if selectedColors.count >= 2 {
                        RadialGradient(
                            gradient: Gradient(colors: selectedColors.map { $0.color }),
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                        .cornerRadius(16)
                    } else {
                        Text("Add at least 2 colors for a radial pattern")
                            .font(fontForMode(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                case .scattered:
                    ZStack {
                        // Background
                        if let firstColor = selectedColors.first {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(firstColor.color.opacity(0.3))
                        }
                        
                        // Scattered circles
                        ForEach(0..<20) { i in
                            Circle()
                                .fill(selectedColors[i % selectedColors.count].color)
                                .frame(width: CGFloat(10 + (i % 5) * 10))
                                .position(
                                    x: CGFloat(40 + (i * 17) % 250),
                                    y: CGFloat(40 + (i * 23) % 150)
                                )
                                .opacity(animateColors ? 1 : 0)
                                .offset(y: animateColors ? 0 : 20)
                                .animation(
                                    Animation.spring(response: 0.5, dampingFraction: 0.6)
                                        .delay(Double(i) * 0.05),
                                    value: animateColors
                                )
                        }
                    }
                    
                case .layered:
                    ZStack {
                        ForEach(0..<min(5, selectedColors.count)) { i in
                            RoundedRectangle(cornerRadius: 16 - CGFloat(i * 2))
                                .fill(selectedColors[i].color)
                                .padding(CGFloat(i * 15))
                                .opacity(animateColors ? 1 : 0)
                                .scaleEffect(animateColors ? 1 : 0.8)
                                .animation(
                                    Animation.spring(response: 0.5, dampingFraction: 0.6)
                                        .delay(Double(i) * 0.1),
                                    value: animateColors
                                )
                        }
                    }
                    
                case .swirled:
                    ZStack {
                        // Background
                        if let firstColor = selectedColors.first {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(firstColor.color.opacity(0.3))
                        }
                        
                        // Swirled paths
                        ForEach(0..<min(3, selectedColors.count)) { i in
                            SwirlShape(
                                loops: 2 + i,
                                loopWidth: 20.0,
                                phase: animateColors ? Double(i) * 0.5 : 0
                            )
                            .stroke(selectedColors[i].color, lineWidth: 10)
                            .opacity(animateColors ? 1 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .delay(Double(i) * 0.2),
                                value: animateColors
                            )
                        }
                    }
                }
            }
            .cornerRadius(16)
        }
        .frame(height: 200)
        .padding(.vertical)
    }
    
    // MARK: - Color Controls
    
    private var colorControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Colors")
                .font(fontForMode(size: 16, weight: .medium))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            
            // Selected colors
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<selectedColors.count, id: \.self) { index in
                        colorButton(index: index)
                    }
                    
                    // Add color button
                    Button(action: {
                        editingColorIndex = nil
                        tempColor = .blue
                        tempMeaning = ""
                        showingColorPicker = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                        }
                    }
                    .disabled(selectedColors.count >= 5)
                    .opacity(selectedColors.count >= 5 ? 0.5 : 1.0)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .shadow(radius: 2)
        )
    }
    
    private func colorButton(index: Int) -> some View {
        let color = selectedColors[index]
        
        return VStack {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 50, height: 50)
                    .shadow(radius: 2)
                
                // Delete button
                if selectedColors.count > 1 {
                    Button(action: {
                        withAnimation {
                            // Explicitly copy, modify, and assign back
                            var mutableColors = selectedColors
                            mutableColors.remove(at: index)
                            selectedColors = mutableColors
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                        }
                    }
                    .offset(x: 20, y: -20)
                }
            }
            .onTapGesture {
                editingColorIndex = index
                tempColor = color.color
                tempMeaning = color.meaning ?? ""
                showingColorPicker = true
            }
            
            if let meaning = color.meaning, !meaning.isEmpty {
                Text(meaning)
                    .font(fontForMode(size: 12))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
    }
    
    // MARK: - Pattern Selection
    
    private var patternSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern")
                .font(fontForMode(size: 16, weight: .medium))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    patternButton(.solid, name: "Solid")
                    patternButton(.gradient, name: "Gradient")
                    patternButton(.radial, name: "Radial")
                    patternButton(.scattered, name: "Scattered")
                    patternButton(.layered, name: "Layered")
                    patternButton(.swirled, name: "Swirled")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .shadow(radius: 2)
        )
    }
    
    private func patternButton(_ pattern: MultiModal.ColorData.ColorPattern, name: String) -> some View {
        Button(action: {
            withAnimation {
                selectedPattern = pattern
            }
        }) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 60, height: 40)
                        .shadow(radius: 1)
                    
                    // Pattern preview
                    Group {
                        switch pattern {
                        case .solid:
                            if let color = selectedColors.first {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(color.color)
                            }
                        case .gradient:
                            LinearGradient(
                                gradient: Gradient(colors: selectedColors.map { $0.color }),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(8)
                        case .radial:
                            RadialGradient(
                                gradient: Gradient(colors: selectedColors.map { $0.color }),
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                            .cornerRadius(8)
                        case .scattered:
                            ZStack {
                                if let color = selectedColors.first {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(color.color.opacity(0.3))
                                }
                                
                                ForEach(0..<5) { i in
                                    Circle()
                                        .fill(selectedColors[i % selectedColors.count].color)
                                        .frame(width: 8)
                                        .position(
                                            x: CGFloat(15 + (i * 10) % 50),
                                            y: CGFloat(15 + (i * 8) % 30)
                                        )
                                }
                            }
                        case .layered:
                            ZStack {
                                ForEach(0..<min(3, selectedColors.count)) { i in
                                    RoundedRectangle(cornerRadius: 8 - CGFloat(i))
                                        .fill(selectedColors[i].color)
                                        .padding(CGFloat(i * 8))
                                }
                            }
                        case .swirled:
                            ZStack {
                                if let color = selectedColors.first {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(color.color.opacity(0.3))
                                }
                                
                                SwirlShape(loops: 2, loopWidth: 10.0, phase: 0)
                                    .stroke(selectedColors[0].color, lineWidth: 5)
                            }
                        }
                    }
                    .cornerRadius(8)
                    
                    // Selection indicator
                    if selectedPattern == pattern {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.themeForChildMode(journalMode).accentColor, lineWidth: 3)
                    }
                }
                
                Text(name)
                    .font(fontForMode(size: 12))
                    .foregroundColor(
                        selectedPattern == pattern ?
                            themeManager.themeForChildMode(journalMode).accentColor :
                            themeManager.themeForChildMode(journalMode).secondaryTextColor
                    )
            }
        }
    }
    
    // MARK: - Intensity Slider
    
    private var intensitySlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How strong is this feeling?")
                    .font(fontForMode(size: 16, weight: .medium))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                
                Spacer()
                
                Text("\(intensity)")
                    .font(fontForMode(size: 18, weight: .bold))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            }
            
            HStack {
                Text("Gentle")
                    .font(fontForMode(size: 12))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                
                Slider(value: Binding(
                    get: { Double(intensity) },
                    set: { intensity = Int($0) }
                ), in: 1...10, step: 1)
                .accentColor(themeManager.themeForChildMode(journalMode).accentColor)
                
                Text("Strong")
                    .font(fontForMode(size: 12))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Description Field
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tell us about this feeling (optional)")
                .font(fontForMode(size: 16, weight: .medium))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            
            TextField("Describe your feeling...", text: $colorDescription)
                .font(fontForMode(size: 16))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.themeForChildMode(journalMode).inputBackgroundColor)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Color Footer
    
    private var colorFooter: some View {
        HStack {
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(fontForMode(size: 16))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(themeManager.themeForChildMode(journalMode).secondaryTextColor, lineWidth: 1)
                    )
            }
            
            Spacer()
            
            // Save button
            Button(action: {
                let finalColorData = MultiModal.ColorData(
                    colors: selectedColors,
                    pattern: selectedPattern,
                    intensity: intensity,
                    description: colorDescription.isEmpty ? nil : colorDescription
                )
                onSave(finalColorData)
            }) {
                Text("Save Colors")
                    .font(fontForMode(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(themeManager.themeForChildMode(journalMode).accentColor)
                    )
            }
        }
        .padding()
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
    }
    
    // MARK: - Color Picker Sheet
    
    private var colorPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Color picker
                ColorPicker("Choose a color", selection: $tempColor)
                    .font(fontForMode(size: 18))
                    .padding()
                
                // Color preview
                Circle()
                    .fill(tempColor)
                    .frame(width: 100, height: 100)
                    .shadow(radius: 2)
                    .padding()
                
                // Color meaning
                VStack(alignment: .leading) {
                    Text("What does this color mean to you?")
                        .font(fontForMode(size: 16, weight: .medium))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    
                    TextField("Color meaning (optional)", text: $tempMeaning)
                        .font(fontForMode(size: 16))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.themeForChildMode(journalMode).inputBackgroundColor)
                        )
                }
                .padding()
                
                // Common meanings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Common meanings:")
                        .font(fontForMode(size: 14, weight: .medium))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            meaningButton("Happy")
                            meaningButton("Sad")
                            meaningButton("Angry")
                            meaningButton("Calm")
                            meaningButton("Excited")
                            meaningButton("Nervous")
                            meaningButton("Proud")
                            meaningButton("Confused")
                            meaningButton("Brave")
                            meaningButton("Tired")
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitle(editingColorIndex != nil ? "Edit Color" : "Add Color", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingColorPicker = false
                },
                trailing: Button("Done") {
                    // Extract color components
                    var red: CGFloat = 0
                    var green: CGFloat = 0
                    var blue: CGFloat = 0
                    var opacity: CGFloat = 0
                    
                    UIColor(tempColor).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
                    
                    let colorInfo = MultiModal.ColorData.ColorInfo(
                        red: Double(red),
                        green: Double(green),
                        blue: Double(blue),
                        opacity: Double(opacity),
                        meaning: tempMeaning.isEmpty ? nil : tempMeaning
                    )
                    
                    withAnimation {
                        if let index = editingColorIndex {
                            selectedColors[index] = colorInfo
                        } else {
                            selectedColors.append(colorInfo)
                        }
                    }
                    
                    showingColorPicker = false
                }
            )
        }
    }
    
    private func meaningButton(_ text: String) -> some View {
        Button(action: {
            tempMeaning = text
        }) {
            Text(text)
                .font(fontForMode(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tempMeaning == text ?
                              themeManager.themeForChildMode(journalMode).accentColor.opacity(0.2) :
                                Color.gray.opacity(0.2))
                )
                .foregroundColor(tempMeaning == text ?
                                 themeManager.themeForChildMode(journalMode).accentColor :
                                    themeManager.themeForChildMode(journalMode).primaryTextColor)
        }
    }
    
    // MARK: - Color Guide Sheet
    
    private var colorGuideSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Colors and Feelings")
                        .font(fontForMode(size: 24, weight: .bold))
                        .padding(.bottom, 8)
                    
                    Text("Colors can help us show feelings that are hard to put into words. Here's what different colors might mean:")
                        .font(fontForMode(size: 16))
                    
                    colorGuideItem(
                        color: .red,
                        name: "Red",
                        meanings: ["Anger", "Energy", "Excitement", "Love", "Danger"]
                    )
                    
                    colorGuideItem(
                        color: .blue,
                        name: "Blue",
                        meanings: ["Calm", "Sadness", "Peace", "Trust", "Relaxation"]
                    )
                    
                    colorGuideItem(
                        color: .yellow,
                        name: "Yellow",
                        meanings: ["Happiness", "Joy", "Excitement", "Nervousness", "Attention"]
                    )
                    
                    colorGuideItem(
                        color: .green,
                        name: "Green",
                        meanings: ["Growth", "Hope", "Relaxation", "Envy", "Nature"]
                    )
                    
                    colorGuideItem(
                        color: .purple,
                        name: "Purple",
                        meanings: ["Creativity", "Mystery", "Sadness", "Wisdom", "Magic"]
                    )
                    
                    colorGuideItem(
                        color: .orange,
                        name: "Orange",
                        meanings: ["Fun", "Warmth", "Enthusiasm", "Creativity", "Energy"]
                    )
                    
                    Text("Remember, colors can mean different things to different people. What matters most is what the colors mean to YOU!")
                        .font(fontForMode(size: 16))
                        .padding(.top)
                    
                    Text("You can also use patterns to show how your feelings mix together or change.")
                        .font(fontForMode(size: 16))
                        .padding(.top)
                }
                .padding()
            }
            .navigationBarTitle("Color Feelings Guide", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                showingGuide = false
            })
        }
    }
    
    private func colorGuideItem(color: Color, name: String, meanings: [String]) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(fontForMode(size: 18, weight: .bold))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                
                Text(meanings.joined(separator: ", "))
                    .font(fontForMode(size: 14))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.themeForChildMode(journalMode).backgroundColor)
        )
    }
    
    // MARK: - Helper Methods
    
    private func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch journalMode {
        case .earlyChildhood, .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight)
        }
    }
}

// MARK: - Swirl Shape

struct SwirlShape: Shape {
    let loops: Int
    let loopWidth: Double
    let phase: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0 - 10
        
        var path = Path()
        
        // Start at center
        path.move(to: center)
        
        // Draw spiral
        for angle in stride(from: 0, to: Double(loops) * 2 * .pi, by: 0.1) {
            let adjustedAngle = angle + phase
            let distance = (adjustedAngle / (2 * .pi)) * radius / Double(loops)
            let x = center.x + CGFloat(cos(adjustedAngle) * distance)
            let y = center.y + CGFloat(sin(adjustedAngle) * distance)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - Preview
struct EmotionColorExpressionView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionColorExpressionView(
            journalMode: .middleChildhood,
            onSave: { _ in },
            onCancel: {}
        )
        .environmentObject(ThemeManager())
    }
}
}
