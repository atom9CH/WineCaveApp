import SwiftUI

struct WineListView: View {
    @StateObject private var viewModel = WineListViewModel()
    @State private var showNewWine = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading wines…")
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text("Failed to load")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if viewModel.wines.isEmpty {
                        Text("No wines yet")
                            .foregroundStyle(.secondary)
                    } else if viewModel.filteredWines.isEmpty {
                        Text("No matches")
                            .foregroundStyle(.secondary)
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
            .searchable(text: $viewModel.searchText, prompt: "Name, country, region, vintage")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("All") { viewModel.filterStorageLocation = nil }
                        Button("Home") { viewModel.filterStorageLocation = .home }
                        Button("Cellar") { viewModel.filterStorageLocation = .cellar }
                    } label: {
                        Image(systemName: viewModel.filterStorageLocation == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
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
    }
}

#Preview {
    WineListView()
}
