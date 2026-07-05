import SwiftUI

struct StartReviewView: View {
    @StateObject private var viewModel = StartReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    var onFinished: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading wines…")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if viewModel.wines.isEmpty {
                    Text("No available wines to review")
                        .foregroundStyle(.secondary)
                } else {
                    List {
                        ForEach(viewModel.wines) { wine in
                            NavigationLink {
                                DrinkWineView(wineId: wine.id, currentQuantity: wine.currentQuantity) {
                                    onFinished()
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wine.name)
                                        .font(.system(size: 15, weight: .medium))
                                    HStack(spacing: 4) {
                                        if let vintage = wine.vintage {
                                            Text(String(vintage))
                                        }
                                        Text("· \(wine.currentQuantity) btl")
                                        if let location = wine.storageLocation {
                                            Text("· \(location == .cellar ? "Cellar" : "Home")")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Start a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.loadAvailableWines()
            }
        }
    }
}
