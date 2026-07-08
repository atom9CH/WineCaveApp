import SwiftUI

struct WineCardRow: View {
    let wine: Wine

    private var isDepleted: Bool {
        wine.status == .depleted
    }

    private var typeColor: Color {
        switch wine.type {
        case .red: return .red
        case .white: return .yellow
        case .rose: return .pink
        case .sparkling: return .cyan
        case nil: return .accentColor
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let urlString = wine.photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDepleted ? Color.gray.opacity(0.15) : typeColor.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: isDepleted ? "wineglass" : "wineglass.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(isDepleted ? .gray : typeColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(wine.name)
                    .font(.system(size: 15, weight: .medium))
                    .strikethrough(isDepleted)
                    .foregroundStyle(isDepleted ? .secondary : .primary)

                HStack(spacing: 4) {
                    if let vintage = wine.vintage {
                        Text(String(vintage))
                    }
                    if let country = wine.country, !country.isEmpty {
                        Text("· \(country)")
                    }
                    if let rating = wine.averageRating {
                        Text("· ★ \(String(format: "%.1f", rating))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if isDepleted {
                    Text("Depleted")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(wine.currentQuantity) btl")
                        .font(.system(size: 12, weight: .medium))
                    if let location = wine.storageLocation {
                        let color: Color = location == .cellar ? .teal : .purple
                        Text(location == .cellar ? "Cellar" : "Home")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.15))
                            .foregroundStyle(color)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isDepleted ? 0.6 : 1)
    }
}
