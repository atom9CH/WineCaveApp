import SwiftUI

struct ConsumeBottleView: View {
    @StateObject private var viewModel = ConsumeBottleViewModel()
    @Environment(\.dismiss) private var dismiss
    var onFinished: () -> Void

    @State private var wineToConfirm: Wine?
    @State private var showConfirmAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                ZStack {
                    content

                    if viewModel.isUpdating {
                        ProgressView()
                    }
                }
            }
            .background(Color("AppBackground"))
            .navigationTitle("Drink a Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.loadAvailableWines()
            }
            .disabled(viewModel.isUpdating)
            .alert("Drink this wine?", isPresented: $showConfirmAlert) {
                Button("Drink", role: .destructive) {
                    if let wine = wineToConfirm {
                        Task {
                            if await viewModel.drink(wine) {
                                onFinished()
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let wineToConfirm {
                    Text("\(wineToConfirm.name) — this will reduce the quantity by 1. No rating will be recorded.")
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Red", isSelected: viewModel.filterTypes.contains(.red), color: .red) {
                    viewModel.toggleType(.red)
                }
                FilterChip(title: "White", isSelected: viewModel.filterTypes.contains(.white), color: .yellow) {
                    viewModel.toggleType(.white)
                }
                FilterChip(title: "Rosé", isSelected: viewModel.filterTypes.contains(.rose), color: .pink) {
                    viewModel.toggleType(.rose)
                }
                FilterChip(title: "Sparkling", isSelected: viewModel.filterTypes.contains(.sparkling), color: .cyan) {
                    viewModel.toggleType(.sparkling)
                }

                if !viewModel.filterTypes.isEmpty {
                    Divider().frame(height: 18)
                    Button {
                        viewModel.filterTypes = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading wines…")
        } else if let error = viewModel.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .font(.caption)
        } else if viewModel.wines.isEmpty {
            Text("No available wines")
                .foregroundStyle(.secondary)
        } else if viewModel.filteredWines.isEmpty {
            Text("No matches for this filter")
                .foregroundStyle(.secondary)
        } else {
            List {
                ForEach(viewModel.filteredWines) { wine in
                    ConsumeWineRow(wine: wine) {
                        wineToConfirm = wine
                        showConfirmAlert = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

private struct ConsumeWineRow: View {
    let wine: Wine
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(wine.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    subtitle
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "wineglass.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var subtitle: some View {
        HStack(spacing: 4) {
            if let vintage = wine.vintage {
                Text(String(vintage))
            }
            Text("· \(wine.currentQuantity) btl")
            if let location = wine.storageLocation {
                Text("· \(location == .cellar ? "Cellar" : "Home")")
            }
        }
    }
}
