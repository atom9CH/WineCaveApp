import Foundation
import Combine
import Supabase

struct WineTypeCount: Identifiable {
    let type: WineType
    let count: Int
    var id: WineType { type }
}

struct StorageCount: Identifiable {
    let location: StorageLocation
    let count: Int
    var id: StorageLocation { location }
}

struct TopRatedWine: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var totalBottlesInStock = 0
    @Published var totalWinesInStock = 0
    @Published var bottlesByType: [WineTypeCount] = []
    @Published var bottlesByStorage: [StorageCount] = []
    @Published var consumedLast30Days = 0
    @Published var consumedAllTime = 0
    @Published var averageRating: Double?
    @Published var topRatedWines: [TopRatedWine] = []

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let wines: [Wine] = try await SupabaseService.client
                .from("wine")
                .select("*, tasting(rating)")
                .execute()
                .value

            let available = wines.filter { $0.status == .available }
            totalBottlesInStock = available.reduce(0) { $0 + $1.currentQuantity }
            totalWinesInStock = available.count

            var typeCounts: [WineType: Int] = [:]
            var storageCounts: [StorageLocation: Int] = [:]
            for wine in available {
                if let type = wine.type {
                    typeCounts[type, default: 0] += wine.currentQuantity
                }
                if let location = wine.storageLocation {
                    storageCounts[location, default: 0] += wine.currentQuantity
                }
            }
            bottlesByType = WineType.allCases.compactMap { type in
                guard let count = typeCounts[type], count > 0 else { return nil }
                return WineTypeCount(type: type, count: count)
            }
            bottlesByStorage = StorageLocation.allCases.compactMap { location in
                guard let count = storageCounts[location], count > 0 else { return nil }
                return StorageCount(location: location, count: count)
            }

            let allRatings = wines.flatMap { ($0.tastings ?? []).compactMap { $0.rating } }
            averageRating = allRatings.isEmpty ? nil : Double(allRatings.reduce(0, +)) / Double(allRatings.count)

            topRatedWines = wines
                .compactMap { wine -> TopRatedWine? in
                    guard let avg = wine.averageRating else { return nil }
                    return TopRatedWine(name: wine.name, rating: avg)
                }
                .sorted { $0.rating > $1.rating }
                .prefix(3)
                .map { $0 }

            struct TastingDateOnly: Codable {
                let id: UUID
                let tastedAt: Date
                enum CodingKeys: String, CodingKey {
                    case id
                    case tastedAt = "tasted_at"
                }
            }
            let allTastings: [TastingDateOnly] = try await SupabaseService.client
                .from("tasting")
                .select("id, tasted_at")
                .execute()
                .value
            consumedAllTime = allTastings.count
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            consumedLast30Days = allTastings.filter { $0.tastedAt >= cutoff }.count
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
