import Foundation
import Combine
import Supabase

@MainActor
final class StartReviewViewModel: ObservableObject {
    @Published var wines: [Wine] = []
    @Published var isLoading = false
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
}
