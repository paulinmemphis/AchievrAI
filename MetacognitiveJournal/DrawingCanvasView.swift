import SwiftUI
import PencilKit
import Combine

/// Extension for multi-modal drawing components
extension MultiModal {
    /// A canvas view for drawing that supports different brush styles, colors, and erasing
    struct DrawingCanvasView: UIViewRepresentable {
    // MARK: - Properties
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @Binding var drawingData: MultiModal.DrawingData?
    let onDrawingChanged: () -> Void
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black)
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        
        canvasView.backgroundColor = .clear
        
        // Show the tool picker automatically
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // If we have drawing data and the canvas is empty, load the drawing
        if let drawingData = drawingData, uiView.drawing.strokes.isEmpty {
            loadDrawing(drawingData, into: uiView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasView
        
        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            self.parent.onDrawingChanged()
            // Use Task instead of DispatchQueue to properly defer state updates
            Task { @MainActor in
                // This ensures the state update happens outside the view update cycle
                self.parent.drawingData = self.convertToDrawingData(from: canvasView)
            }
        }
        
        private func convertToDrawingData(from canvasView: PKCanvasView) -> MultiModal.DrawingData {
            var strokes: [MultiModal.DrawingData.Stroke] = []
            
            for pkStroke in canvasView.drawing.strokes {
                let points = pkStroke.path.map { CGPoint(x: $0.location.x, y: $0.location.y) }
                
                // Extract color components from the stroke
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                
                pkStroke.ink.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                let colorInfo = MultiModal.ColorData.ColorInfo(
                    red: Double(red),
                    green: Double(green),
                    blue: Double(blue),
                    opacity: Double(alpha),
                    meaning: nil
                )
                
                let stroke = MultiModal.DrawingData.Stroke(
                    points: points,
                    color: colorInfo,
                    // Fix: Get width from the stroke path's points, not the ink
                    width: pkStroke.path.first?.size.width ?? 1.0
                )
                
                strokes.append(stroke)
            }
            
            return MultiModal.DrawingData(
                strokes: strokes,
                background: nil,
                size: canvasView.bounds.size
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadDrawing(_ drawingData: MultiModal.DrawingData, into canvasView: PKCanvasView) {
        // Convert DrawingData to PKDrawing
        var pkStrokes: [PKStroke] = []
        
        for stroke in drawingData.strokes {
            // Create PKStrokePoints from our points
            var pkStrokePoints: [PKStrokePoint] = []
            
            for (index, point) in stroke.points.enumerated() {
                // Create a stroke point with appropriate parameters
                let pkStrokePoint = PKStrokePoint(
                    location: CGPoint(x: point.x, y: point.y),
                    timeOffset: TimeInterval(index) * 0.01, // Simulate timing
                    size: CGSize(width: stroke.width, height: stroke.width),
                    opacity: CGFloat(stroke.color.opacity),
                    force: 1.0, // Default force
                    azimuth: 0, // Default azimuth
                    altitude: 0 // Default altitude
                )
                pkStrokePoints.append(pkStrokePoint)
            }
            
            // Create a stroke path from the points
            let path = PKStrokePath(controlPoints: pkStrokePoints, creationDate: Date())
            
            // Create the ink with color and width
            let color = UIColor(
                red: CGFloat(stroke.color.red),
                green: CGFloat(stroke.color.green),
                blue: CGFloat(stroke.color.blue),
                alpha: CGFloat(stroke.color.opacity)
            )
            
            let ink = PKInk(.pen, color: color)
            
            // Create the stroke and add it to our array
            let pkStroke = PKStroke(ink: ink, path: path)
            pkStrokes.append(pkStroke)
        }
        
        // Create a PKDrawing from the strokes and set it to the canvas
        let pkDrawing = PKDrawing(strokes: pkStrokes)
        canvasView.drawing = pkDrawing
    }
}

/// A wrapper view that provides a complete drawing experience with tools and controls
struct DrawingToolView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Properties
    @Binding var drawingData: MultiModal.DrawingData?
    let onSave: (MultiModal.DrawingData) -> Void
    let onCancel: () -> Void
    // Use the correct Enum type
    let journalMode: ChildJournalMode
    let emotionContext: Bool
    let metaphorContext: Bool
    
    // MARK: - State
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showingColorMeaningSheet = false
    @State private var selectedColor: MultiModal.ColorData.ColorInfo?
    @State private var colorMeanings: [UIColor: String] = [:]
    @State private var showingMetaphorGuide = false
    @State private var showingEmotionGuide = false
    @State private var currentBackgroundColor: Color = .white
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with tools
            drawingHeader
            
            // Canvas
            ZStack {
                // Background
                Rectangle()
                    .fill(currentBackgroundColor)
                    .border(Color.gray.opacity(0.3), width: 1)
                
                // Drawing canvas
                DrawingCanvasView(
                    canvasView: $canvasView,
                    toolPicker: $toolPicker,
                    drawingData: $drawingData,
                    onDrawingChanged: {
                        // Handle drawing changes
                    }
                )
                .background(Color.clear)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 300)
            
            // Footer with actions
            drawingFooter
        }
        // Fix: Access backgroundColor via the theme appropriate for the journalMode
        .background(themeManager.themeForChildMode(journalMode).backgroundColor)
        .sheet(isPresented: $showingColorMeaningSheet) {
            colorMeaningSheet
        }
        .sheet(isPresented: $showingMetaphorGuide) {
            metaphorGuideSheet
        }
        .sheet(isPresented: $showingEmotionGuide) {
            emotionGuideSheet
        }
    }
    
    // MARK: - Drawing Header
    
    private var drawingHeader: some View {
        HStack {
            // Title based on context
            Text(drawingTitle)
                .font(fontForMode(size: 18, weight: .bold))
                // Fix: Access color via theme
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                .lineLimit(1)
                .padding(.horizontal)
            
            Spacer()
            
            // Help button
            Button(action: {
                if metaphorContext {
                    showingMetaphorGuide = true
                } else if emotionContext {
                    showingEmotionGuide = true
                }
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                    // Fix: Correct to accentColor
                    .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            }
            .opacity(metaphorContext || emotionContext ? 1 : 0)
            
            // Background color picker
            Menu {
                Button(action: { currentBackgroundColor = .white }) {
                    Label("White", systemImage: "circle.fill")
                        .foregroundColor(.white)
                }
                
                Button(action: { currentBackgroundColor = Color(UIColor.systemGray6) }) {
                    Label("Light Gray", systemImage: "circle.fill")
                        .foregroundColor(Color(UIColor.systemGray6))
                }
                
                Button(action: { currentBackgroundColor = Color(UIColor.systemBackground) }) {
                    Label("System Background", systemImage: "circle.fill")
                        .foregroundColor(Color(UIColor.systemBackground))
                }
                
                if emotionContext {
                    Divider()
                    
                    Button(action: { currentBackgroundColor = .blue.opacity(0.1) }) {
                        Label("Calm Blue", systemImage: "circle.fill")
                            .foregroundColor(.blue.opacity(0.1))
                    }
                    
                    Button(action: { currentBackgroundColor = .yellow.opacity(0.1) }) {
                        Label("Happy Yellow", systemImage: "circle.fill")
                            .foregroundColor(.yellow.opacity(0.1))
                    }
                    
                    Button(action: { currentBackgroundColor = .red.opacity(0.1) }) {
                        Label("Angry Red", systemImage: "circle.fill")
                            .foregroundColor(.red.opacity(0.1))
                    }
                    
                    Button(action: { currentBackgroundColor = .purple.opacity(0.1) }) {
                        Label("Sad Purple", systemImage: "circle.fill")
                            .foregroundColor(.purple.opacity(0.1))
                    }
                }
            } label: {
                Image(systemName: "rectangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            }
            
            // Color meaning button
            if emotionContext {
                Button(action: {
                    showingColorMeaningSheet = true
                }) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                }
            }
        }
        .padding()
        // Fix: Access color via theme
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
    }
    
    // MARK: - Drawing Footer
    
    private var drawingFooter: some View {
        HStack {
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .padding()
                    .frame(maxWidth: .infinity)
                    // Fix: Access color via theme
                    .background(themeManager.themeForChildMode(journalMode).secondaryTextColor.opacity(0.2))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            // Clear button
            Button(action: {
                canvasView.drawing = PKDrawing()
            }) {
                Text("Clear")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            // Fix: Access color via theme
                            .fill(themeManager.themeForChildMode(journalMode).secondaryTextColor.opacity(0.1))
                    )
                    .foregroundColor(.red)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            // Save button
            Button(action: {
                if let data = drawingData {
                    onSave(data)
                }
            }) {
                Text("Save")
                    .padding()
                    .frame(maxWidth: .infinity)
                    // Fix: Access color via theme
                    .background(themeManager.themeForChildMode(journalMode).accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        // Fix: Access color via theme
        .background(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
    }
    
    // MARK: - Color Meaning Sheet
    
    private var colorMeaningSheet: some View {
        NavigationView {
            VStack {
                Text("What do your colors mean?")
                    .font(fontForMode(size: 20, weight: .bold))
                    .padding()
                
                Text("Tap on a color to tell us what it means to you.")
                    .font(fontForMode(size: 16))
                    // Fix: Correct to secondaryTextColor
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Common emotion colors
                        colorMeaningRow(color: .red, defaultMeaning: "Anger, Energy, Passion")
                        colorMeaningRow(color: .blue, defaultMeaning: "Calm, Peace, Sadness")
                        colorMeaningRow(color: .yellow, defaultMeaning: "Happiness, Joy, Excitement")
                        colorMeaningRow(color: .green, defaultMeaning: "Growth, Hope, Relaxation")
                        colorMeaningRow(color: .purple, defaultMeaning: "Creativity, Mystery, Sadness")
                        colorMeaningRow(color: .orange, defaultMeaning: "Fun, Warmth, Enthusiasm")
                        colorMeaningRow(color: .pink, defaultMeaning: "Love, Gentleness, Sweetness")
                        colorMeaningRow(color: .black, defaultMeaning: "Power, Fear, Strength")
                        colorMeaningRow(color: .gray, defaultMeaning: "Neutral, Boredom, Uncertainty")
                        colorMeaningRow(color: .brown, defaultMeaning: "Comfort, Stability, Earthiness")
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Color Meanings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                showingColorMeaningSheet = false
            })
            // Fix: Access color via theme
            .background(themeManager.themeForChildMode(journalMode).backgroundColor)
        }
    }
    
    private func colorMeaningRow(color: Color, defaultMeaning: String) -> some View {
        let uiColor = UIColor(color)
        
        return HStack {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            TextField(
                "What does this color mean to you?",
                text: Binding(
                    get: { colorMeanings[uiColor] ?? defaultMeaning },
                    set: { colorMeanings[uiColor] = $0 }
                )
            )
            .font(fontForMode(size: 16))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemGray6))
            )
        }
    }
    
    // MARK: - Metaphor Guide Sheet
    
    private var metaphorGuideSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Visual Thinking Metaphors")
                        .font(fontForMode(size: 24, weight: .bold))
                        .padding(.bottom, 8)
                    
                    Text("A visual metaphor helps you show how your thinking works using pictures. Here are some ideas:")
                        .font(fontForMode(size: 16))
                    
                    metaphorGuideItem(
                        title: "Journey",
                        description: "Draw a path or road showing the steps in your thinking",
                        examples: ["A winding road with obstacles", "A map with different routes", "Stepping stones across a river"]
                    )
                    
                    metaphorGuideItem(
                        title: "Container",
                        description: "Use boxes, jars, or containers to show different thoughts",
                        examples: ["Boxes with labels for each idea", "Jars filled with different colors", "A backpack with tools inside"]
                    )
                    
                    metaphorGuideItem(
                        title: "Machine",
                        description: "Create a machine that shows how your thoughts work together",
                        examples: ["A factory with conveyor belts", "Gears turning together", "A computer with inputs and outputs"]
                    )
                    
                    metaphorGuideItem(
                        title: "Nature",
                        description: "Use elements from nature to represent your thinking",
                        examples: ["A tree with branches for different ideas", "A garden with different plants", "A river flowing with thoughts"]
                    )
                    
                    metaphorGuideItem(
                        title: "Weather",
                        description: "Show your thinking climate with weather patterns",
                        examples: ["Storm clouds for confusion", "Sunshine for clarity", "Rainbow for many ideas"]
                    )
                    
                    Text("Remember, there's no right or wrong way to draw your thinking. The most important thing is that it makes sense to you!")
                        .font(fontForMode(size: 16))
                        .padding(.top)
                }
                .padding()
            }
            .navigationBarTitle("Thinking Pictures Guide", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                showingMetaphorGuide = false
            })
            // Fix: Access color via theme
            .background(themeManager.themeForChildMode(journalMode).backgroundColor)
        }
    }
    
    private func metaphorGuideItem(title: String, description: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(fontForMode(size: 18, weight: .bold))
                // Fix: Access color via theme
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            
            Text(description)
                .font(fontForMode(size: 16))
            
            Text("Examples:")
                .font(fontForMode(size: 14, weight: .medium))
                .padding(.top, 4)
            
            ForEach(examples, id: \.self) { example in
                HStack(alignment: .top) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .padding(.top, 6)
                    
                    Text(example)
                        .font(fontForMode(size: 14))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                // Fix: Access color via theme
                .fill(themeManager.themeForChildMode(journalMode).backgroundColor)
        )
    }
    
    // MARK: - Emotion Guide Sheet
    
    private var emotionGuideSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Drawing Your Feelings")
                        .font(fontForMode(size: 24, weight: .bold))
                        // Fix: Access color via theme
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                        .padding(.bottom, 10)

                    Text("Colors can be powerful ways to show emotions! Here are some common ideas, but feel free to use colors in your own unique way.")
                        .font(fontForMode(size: 16))
                    
                    emotionGuideItem(
                        title: "Colors",
                        description: "Different colors can show different feelings",
                        examples: [
                            "Red might show anger or excitement",
                            "Blue might show calm or sadness",
                            "Yellow might show happiness or nervousness"
                        ]
                    )
                    
                    emotionGuideItem(
                        title: "Shapes",
                        description: "The shapes you draw can express feelings too",
                        examples: [
                            "Sharp, jagged shapes for angry or stressed feelings",
                            "Smooth, rounded shapes for calm or peaceful feelings",
                            "Big shapes for strong feelings, small for quiet ones"
                        ]
                    )
                    
                    emotionGuideItem(
                        title: "Lines",
                        description: "The way you draw lines can show how you feel",
                        examples: [
                            "Fast, heavy lines might show strong emotions",
                            "Light, gentle lines might show quiet feelings",
                            "Swirly lines might show confusion or excitement"
                        ]
                    )
                    
                    emotionGuideItem(
                        title: "Symbols",
                        description: "You can use symbols to represent feelings",
                        examples: [
                            "Hearts, stars, or suns for happy feelings",
                            "Clouds, rain, or tears for sad feelings",
                            "Fire or lightning for angry feelings"
                        ]
                    )
                    
                    Text("Remember, your feelings are yours! There's no wrong way to draw them. The most important thing is that your drawing helps you express how you feel.")
                        .font(fontForMode(size: 16))
                        .padding(.top)
                }
                .padding()
            }
            .navigationBarTitle("Emotion Drawing Guide", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                showingEmotionGuide = false
            })
            // Fix: Access color via theme
            .background(themeManager.themeForChildMode(journalMode).backgroundColor)
        }
    }
    
    private func emotionGuideItem(title: String, description: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(fontForMode(size: 18, weight: .bold))
                // Fix: Access color via theme
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            
            Text(description)
                .font(fontForMode(size: 16))
            
            ForEach(examples, id: \.self) { example in
                HStack(alignment: .top) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .padding(.top, 6)
                    
                    Text(example)
                        .font(fontForMode(size: 14))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                // Fix: Access color via theme
                .fill(themeManager.themeForChildMode(journalMode).backgroundColor)
        )
    }
    
    // MARK: - Helper Methods
    
    private var drawingTitle: String {
        if metaphorContext {
            return "Draw Your Thinking"
        } else if emotionContext {
            return "Draw Your Feelings"
        } else {
            return "Drawing"
        }
    }
    
    private func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch journalMode {
        case .earlyChildhood, .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight)
        }
    }
}
// MARK: - Preview
struct DrawingToolView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingToolView(
            drawingData: .constant(nil),
            onSave: { _ in },
            onCancel: {},
            journalMode: .middleChildhood,
            emotionContext: true,
            metaphorContext: false
        )
        .environmentObject(ThemeManager())
    }
}

} // Add missing closing brace for extension MultiModal
