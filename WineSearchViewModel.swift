import Foundation
import Combine
import Supabase

struct GrapeVarietyEmbed: Codable {
    let name: String
}

@MainActor
final class WineSearchViewModel: ObservableObject {
    @Published var wines: [Wine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var searchText = ""
    @Published var grapeVarietyText = ""
    @Published var vintageFrom = ""
    @Published var vintageTo = ""
    @Published var minimumRating = 0

    var hasActiveFilters: Bool {
        !searchText.isEmpty || !grapeVarietyText.isEmpty || !vintageFrom.isEmpty || !vintageTo.isEmpty || minimumRating > 0
    }

    func resetFilters() {
        searchText = ""
        grapeVarietyText = ""
        vintageFrom = ""
        vintageTo = ""
        minimumRating = 0
    }

    func loadWines() async {
        isLoading = true
        errorMessage = nil
        do {
            wines = try await SupabaseService.client
                .from("wine")
                .select("*, tasting(rating), grape_variety(name)")
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var results: [Wine] {
        wines.filter { wine in
            let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            let matchesText: Bool
            if query.isEmpty {
                matchesText = true
            } else {
                matchesText = wine.name.lowercased().contains(query)
                    || (wine.country?.lowercased().contains(query) ?? false)
                    || (wine.region?.lowercased().contains(query) ?? false)
            }

            let grapeQuery = grapeVarietyText.trimmingCharacters(in: .whitespaces).lowercased()
            let matchesGrape: Bool
            if grapeQuery.isEmpty {
                matchesGrape = true
            } else {
                let names = (wine.grapeVarietyNames ?? []).map { $0.name.lowercased() }
                matchesGrape = names.contains { $0.contains(grapeQuery) }
            }

            let fromYear = Int(vintageFrom)
            let toYear = Int(vintageTo)
            let matchesVintage: Bool
            if let vintage = wine.vintage {
                let matchesFrom = fromYear.map { vintage >= $0 } ?? true
                let matchesTo = toYear.map { vintage <= $0 } ?? true
                matchesVintage = matchesFrom && matchesTo
            } else {
                matchesVintage = fromYear == nil && toYear == nil
            }

            let matchesRating = minimumRating == 0 || (wine.averageRating ?? 0) >= Double(minimumRating)

            return matchesText && matchesGrape && matchesVintage && matchesRating
        }
    }
}
