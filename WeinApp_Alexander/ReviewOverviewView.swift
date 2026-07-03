import SwiftUI

struct ReviewOverviewView: View {
    @StateObject private var viewModel = ReviewOverviewViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading reviews…")
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if viewModel.tastings.isEmpty {
                Text("No reviews yet")
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
                            .frame(width: 48, height: 48)
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
                            HStack(spacing: 2) {
                                ForEach(0..<5) { star in
                                    Image(systemName: star < tasting.rating ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.yellow)
                                }
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
        .navigationTitle("Review Overview")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadTastings()
        }
    }
}
