import SwiftUI

struct ErrorView: View {
    let error: Error
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            Text(error.localizedDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
