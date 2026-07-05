import SwiftUI

struct WineListView: View {
    @StateObject private var viewModel = WineListViewModel()
    @State private var showNewWine = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                filterBar

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading wines…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text("Failed to load")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.wines.isEmpty {
                        Text("No wines yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredWines.isEmpty {
                        VStack(spacing: 10) {
                            Text("No matches")
                                .foregroundStyle(.secondary)
                            if viewModel.activeFilterCount > 0 {
                                Button("Clear filters") { viewModel.resetFilters() }
                                    .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            Section {
                                ForEach(viewModel.filteredWines) { wine in
                                    NavigationLink {
                                        WineDetailView(wine: wine) {
                                            Task { await viewModel.loadWines() }
                                        }
                                    } label: {
                                        WineCardRow(wine: wine)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                }
                            } header: {
                                Text("\(viewModel.totalBottles) bottles · \(viewModel.totalWines) wines")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                                    .padding(.leading, 4)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }

            Button {
                showNewWine = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
        .navigationTitle("My Wine Cellar")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Name, country, region, vintage")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(WineSortOption.allCases) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            if viewModel.sortOption == option {
                                Label(option.rawValue, systemImage: "checkmark")
                            } else {
                                Text(option.rawValue)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
        }
        .sheet(isPresented: $showNewWine) {
            NewWineView {
                Task { await viewModel.loadWines() }
            }
        }
        .task {
            await viewModel.loadWines()
        }
        .refreshable {
            await viewModel.loadWines()
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: viewModel.filterStorageLocation == nil, color: .gray) {
                    viewModel.filterStorageLocation = nil
                }
                FilterChip(title: "Home", isSelected: viewModel.filterStorageLocation == .home, color: .purple) {
                    viewModel.filterStorageLocation = viewModel.filterStorageLocation == .home ? nil : .home
                }
                FilterChip(title: "Cellar", isSelected: viewModel.filterStorageLocation == .cellar, color: .teal) {
                    viewModel.filterStorageLocation = viewModel.filterStorageLocation == .cellar ? nil : .cellar
                }

                Divider().frame(height: 18)

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

                if viewModel.activeFilterCount > 0 {
                    Divider().frame(height: 18)
                    Button {
                        viewModel.resetFilters()
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
}

#Preview {
    NavigationStack {
        WineListView()
    }
}
