import Foundation
import Combine
import Supabase
import UIKit

@MainActor
final class DrinkWineViewModel: ObservableObject {
    let wineId: UUID
    let currentQuantity: Int

    @Published var rating = 3
    @Published var note = ""
    @Published var selectedImage: UIImage?
    @Published var isSaving = false
    @Published var errorMessage: String?

    init(wineId: UUID, currentQuantity: Int) {
        self.wineId = wineId
        self.currentQuantity = currentQuantity
    }

    private struct QuantityUpdatePayload: Encodable {
        let current_quantity: Int
    }

    private struct TastingPayload: Encodable {
        let wine_id: UUID
        let rating: Int
        let note: String?
        let photo_url: String?
    }

    /// Reduziert die Menge um 1, lädt optional ein Foto hoch und legt einen Tasting-Eintrag an.
    func save() async -> Bool {
        isSaving = true
        errorMessage = nil

        let newQuantity = max(0, currentQuantity - 1)

        do {
            try await SupabaseService.client
                .from("wine")
                .update(QuantityUpdatePayload(current_quantity: newQuantity))
                .eq("id", value: wineId)
                .execute()

            var photoURL: String?
            if let selectedImage, let data = selectedImage.jpegData(compressionQuality: 0.8) {
                let path = "\(UUID().uuidString).jpg"
                try await SupabaseService.client.storage
                    .from("tasting-photos")
                    .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                photoURL = try SupabaseService.client.storage
                    .from("tasting-photos")
                    .getPublicURL(path: path)
                    .absoluteString
            }

            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            let payload = TastingPayload(
                wine_id: wineId,
                rating: rating,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                photo_url: photoURL
            )
            try await SupabaseService.client
                .from("tasting")
                .insert(payload)
                .execute()

            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}
