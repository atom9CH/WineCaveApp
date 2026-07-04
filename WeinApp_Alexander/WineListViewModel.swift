import Foundation
import Combine
import Supabase

enum WineSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest first"
    case nameAZ = "Name (A–Z)"
    case vintageNewest = "Vintage (newest)"
    case vintageOldest = "Vintage (oldest)"
    case ratingHighest = "Top rated"

    var id: String { rawValue }
}

@MainActor
final class WineListViewModel: ObservableObject {
    @Published var wines: [Wine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var searchText = ""
    @Published var filterStorageLocation: StorageLocation?
    @Published var filterTypes: Set<WineType> = []
    @Published var sortOption: WineSortOption = .newest

    var activeFilterCount: Int {
        (filterStorageLocation == nil ? 0 : 1) + filterTypes.count
    }

    func toggleType(_ type: WineType) {
        if filterTypes.contains(type) {
            filterTypes.remove(type)
        } else {
            filterTypes.insert(type)
        }
    }

    func resetFilters() {
        filterStorageLocation = nil
        filterTypes = []
    }

    var filteredWines: [Wine] {
        let base = wines.filter { wine in
            let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            let matchesSearch: Bool
            if query.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = wine.name.lowercased().contains(query)
                    || (wine.country?.lowercased().contains(query) ?? false)
                    || (wine.region?.lowercased().contains(query) ?? false)
                    || (wine.type?.displayName.lowercased().contains(query) ?? false)
                    || (wine.vintage.map { String($0) }?.contains(query) ?? false)
            }
            let matchesStorage = filterStorageLocation == nil || wine.storageLocation == filterStorageLocation
            let matchesType = filterTypes.isEmpty || (wine.type.map { filterTypes.contains($0) } ?? false)
            return matchesSearch && matchesStorage && matchesType
        }

        switch sortOption {
        case .newest:
            return base
        case .nameAZ:
            return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .vintageNewest:
            return base.sorted { ($0.vintage ?? 0) > ($1.vintage ?? 0) }
        case .vintageOldest:
            return base.sorted { ($0.vintage ?? Int.max) < ($1.vintage ?? Int.max) }
        case .ratingHighest:
            return base.sorted { ($0.averageRating ?? -1) > ($1.averageRating ?? -1) }
        }
    }

    var totalBottles: Int {
        wines.filter { $0.status == .available }.reduce(0) { $0 + $1.currentQuantity }
    }

    var totalWines: Int {
        wines.filter { $0.status == .available }.count
    }

    func loadWines() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: [Wine] = try await SupabaseService.client
                .from("wine")
                .select("*, tasting(rating)")
                .order("created_at", ascending: false)
                .execute()
                .value
            wines = response
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
