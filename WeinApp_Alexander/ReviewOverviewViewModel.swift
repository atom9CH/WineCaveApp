import Foundation
import Combine
import Supabase

struct WineName: Codable {
    let name: String
}

struct TastingWithWine: Identifiable, Codable {
    let id: UUID
    var rating: Int
    var note: String?
    var photoURL: String?
    var tastedAt: Date
    var wine: WineName

    enum CodingKeys: String, CodingKey {
        case id
        case rating
        case note
        case photoURL = "photo_url"
        case tastedAt = "tasted_at"
        case wine
    }
}

@MainActor
final class ReviewOverviewViewModel: ObservableObject {
    @Published var tastings: [TastingWithWine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadTastings() async {
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
