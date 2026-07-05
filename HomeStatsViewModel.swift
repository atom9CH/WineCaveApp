import Foundation
import Combine
import Supabase

@MainActor
final class HomeStatsViewModel: ObservableObject {
    @Published var totalBottles = 0
    @Published var drunkLast30Days = 0

    func load() async {
        async let bottlesTask: Void = loadBottles()
        async let drunkTask: Void = loadDrunkLast30Days()
        _ = await (bottlesTask, drunkTask)
    }

    private func loadBottles() async {
        do {
            let wines: [Wine] = try await SupabaseService.client
                .from("wine")
                .select()
                .eq("status", value: "available")
                .execute()
                .value
            totalBottles = wines.reduce(0) { $0 + $1.currentQuantity }
        } catch {
            // Kompakte Leiste: Fehler hier bewusst nicht anzeigen, nur ignorieren
        }
    }

    private func loadDrunkLast30Days() async {
        do {
            struct TastingIdOnly: Codable {
                let id: UUID
                let tastedAt: Date
                enum CodingKeys: String, CodingKey {
                    case id
                    case tastedAt = "tasted_at"
                }
            }
            let all: [TastingIdOnly] = try await SupabaseService.client
                .from("tasting")
                .select("id, tasted_at")
                .execute()
                .value
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            drunkLast30Days = all.filter { $0.tastedAt >= cutoff }.count
        } catch {
            // ignorieren
        }
    }
}
