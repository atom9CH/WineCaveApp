import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading statistics…")
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                List {
                    Section("Overview") {
                        StatRow(label: "Bottles in stock", value: "\(viewModel.totalBottlesInStock)")
                        StatRow(label: "Different wines", value: "\(viewModel.totalWinesInStock)")
                        if let avg = viewModel.averageRating {
                            StatRow(label: "Average rating", value: String(format: "%.1f ★", avg))
                        }
                    }

                    Section("Consumption") {
                        StatRow(label: "Last 30 days", value: "\(viewModel.consumedLast30Days)")
                        StatRow(label: "All time", value: "\(viewModel.consumedAllTime)")
                    }

                    if !viewModel.bottlesByType.isEmpty {
                        Section("By Type") {
                            ForEach(viewModel.bottlesByType) { item in
                                StatRow(label: item.type.displayName, value: "\(item.count)")
                            }
                        }
                    }

                    if !viewModel.bottlesByStorage.isEmpty {
                        Section("By Storage") {
                            ForEach(viewModel.bottlesByStorage) { item in
                                StatRow(label: item.location == .cellar ? "Cellar" : "Home", value: "\(item.count)")
                            }
                        }
                    }

                    if !viewModel.topRatedWines.isEmpty {
                        Section("Top Rated") {
                            ForEach(viewModel.topRatedWines) { wine in
                                StatRow(label: wine.name, value: String(format: "%.1f ★", wine.rating))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
