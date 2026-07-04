import Foundation
import Combine
import Supabase

@MainActor
final class ConsumeBottleViewModel: ObservableObject {
    @Published var wines: [Wine] = []
    @Published var isLoading = false
    @Published var isUpdating = false
    @Published var errorMessage: String?

    func loadAvailableWines() async {
        isLoading = true
        errorMessage = nil
        do {
            wines = try await SupabaseService.client
                .from("wine")
                .select()
                .eq("status", value: "available")
                .order("name", ascending: true)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private struct QuantityUpdatePayload: Encodable {
        let current_quantity: Int
    }

    private struct PlainTastingPayload: Encodable {
        let wine_id: UUID
        let rating: Int?
        let note: String?
    }

    /// Reduziert die Menge um 1 und legt einen Konsum-Eintrag OHNE Bewertung an.
    func drink(_ wine: Wine) async -> Bool {
        isUpdating = true
        errorMessage = nil

        let newQuantity = max(0, wine.currentQuantity - 1)

        do {
            try await SupabaseService.client
                .from("wine")
                .update(QuantityUpdatePayload(current_quantity: newQuantity))
                .eq("id", value: wine.id)
                .execute()

            try await SupabaseService.client
                .from("tasting")
                .insert(PlainTastingPayload(wine_id: wine.id, rating: nil, note: nil))
                .execute()

            await loadAvailableWines()
            isUpdating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isUpdating = false
            return false
        }
    }
}
