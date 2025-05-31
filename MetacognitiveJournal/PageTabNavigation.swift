import SwiftUI

/// A reusable navigation component that displays page tab buttons at the bottom of the screen
struct PageTabNavigation: View {
    @Binding var currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Previous page button
            Button(action: {
                if currentPage > 0 {
                    let newPage = currentPage - 1
                    currentPage = newPage
                    onPageChange(newPage)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(currentPage > 0 ? .accentColor : .gray.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .disabled(currentPage == 0)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Next page button
            Button(action: {
                if currentPage < totalPages - 1 {
                    let newPage = currentPage + 1
                    currentPage = newPage
                    onPageChange(newPage)
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(currentPage < totalPages - 1 ? .accentColor : .gray.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .disabled(currentPage == totalPages - 1)
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -2)
        )
    }
}

struct PageTabNavigation_Previews: PreviewProvider {
    @State static var currentPage = 1
    
    static var previews: some View {
        PageTabNavigation(
            currentPage: .constant(1),
            totalPages: 3,
            onPageChange: { _ in }
        )
        .previewLayout(.sizeThatFits)
    }
}
