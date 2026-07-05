import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.12))
                .foregroundStyle(isSelected ? .white : color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
