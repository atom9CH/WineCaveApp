import Foundation
import Combine
import Supabase

@MainActor
final class DrinkHistoryViewModel: ObservableObject {
    @Published var tastings: [TastingWithWine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Lädt ALLE Konsum-Ereignisse, unabhängig davon ob eine Bewertung vorliegt.
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        do {
            tastings = try await SupabaseService.client
                .from("tasting")
                .select("*, wine(name)")
                .order("tasted_at", ascending: false)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
