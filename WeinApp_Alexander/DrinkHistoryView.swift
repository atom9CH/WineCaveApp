import SwiftUI

struct DrinkHistoryView: View {
    @StateObject private var viewModel = DrinkHistoryViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading history…")
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if viewModel.tastings.isEmpty {
                Text("No drink history yet")
                    .foregroundStyle(.secondary)
            } else {
                List(viewModel.tastings) { tasting in
                    HStack(alignment: .top, spacing: 10) {
                        if let photoURL = tasting.photoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.15)
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tasting.wine.name)
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Text(tasting.tastedAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if let rating = tasting.rating {
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { star in
                                        Image(systemName: star < rating ? "star.fill" : "star")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.yellow)
                                    }
                                }
                            } else {
                                Text("Consumed, no rating")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if let note = tasting.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Drink History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory()
        }
    }
}
