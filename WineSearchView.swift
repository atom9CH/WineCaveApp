import SwiftUI

struct WineSearchView: View {
    @StateObject private var viewModel = WineSearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchForm

            Divider()

            Group {
                if viewModel.isLoading {
                    ProgressView("Loading wines…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.results.isEmpty {
                    VStack(spacing: 10) {
                        Text("No matches")
                            .foregroundStyle(.secondary)
                        if viewModel.hasActiveFilters {
                            Button("Clear all filters") { viewModel.resetFilters() }
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.results) { wine in
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
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color("AppBackground"))
                }
            }
        }
        .background(Color("AppBackground"))
        .navigationTitle("Wine Search")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadWines()
        }
    }

    private var searchForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Name, country, region", text: $viewModel.searchText)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack {
                Image(systemName: "leaf")
                    .foregroundStyle(.secondary)
                TextField("Grape variety", text: $viewModel.grapeVarietyText)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vintage from")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 2015", text: $viewModel.vintageFrom)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vintage to")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 2023", text: $viewModel.vintageTo)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Minimum rating")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= viewModel.minimumRating ? "star.fill" : "star")
                            .foregroundStyle(star <= viewModel.minimumRating ? .yellow : .secondary)
                            .onTapGesture {
                                viewModel.minimumRating = (viewModel.minimumRating == star) ? 0 : star
                            }
                    }
                    Spacer()
                    if viewModel.minimumRating > 0 {
                        Text("\(viewModel.minimumRating)+ ★")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if viewModel.hasActiveFilters {
                Button("Clear all filters") {
                    viewModel.resetFilters()
                }
                .font(.subheadline)
            }
        }
        .padding(16)
    }
}
