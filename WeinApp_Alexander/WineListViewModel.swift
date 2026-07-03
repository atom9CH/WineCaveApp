import Foundation
import Combine
import Supabase

@MainActor
final class WineListViewModel: ObservableObject {
    @Published var wines: [Wine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var searchText = ""
    @Published var filterStorageLocation: StorageLocation?

    var filteredWines: [Wine] {
        wines.filter { wine in
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
            return matchesSearch && matchesStorage
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
