import Foundation
import Combine
import Supabase
import UIKit

@MainActor
final class NewWineViewModel: ObservableObject {
    @Published var name = ""
    @Published var type: WineType = .red
    @Published var vintage = ""
    @Published var country = ""
    @Published var region = ""
    @Published var storageLocation: StorageLocation = .cellar
    @Published var purchaseLocation: PurchaseLocation = .denner
    @Published var purchaseLocationOtherText = ""
    @Published var quantity = 1
    @Published var grapeVarieties: [String] = [""]
    @Published var selectedImage: UIImage?

    @Published var isSaving = false
    @Published var errorMessage: String?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private struct NewWinePayload: Encodable {
        let name: String
        let type: String
        let vintage: Int?
        let country: String?
        let region: String?
        let storage_location: String
        let purchase_location: String
        let purchase_location_other_text: String?
        let original_quantity: Int
        let current_quantity: Int
        let photo_url: String?
    }

    private struct GrapeVarietyPayload: Encodable {
        let wine_id: UUID
        let name: String
    }

    private func uploadPhotoIfNeeded() async throws -> String? {
        guard let selectedImage, let data = selectedImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        let path = "\(UUID().uuidString).jpg"
        try await SupabaseService.client.storage
            .from("wine-photos")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        return try SupabaseService.client.storage
            .from("wine-photos")
            .getPublicURL(path: path)
            .absoluteString
    }

    /// Saves the wine and its grape varieties. Returns true on success.
    func save() async -> Bool {
        guard isValid else { return false }
        isSaving = true
        errorMessage = nil

        do {
            let photoURL = try await uploadPhotoIfNeeded()

            let payload = NewWinePayload(
                name: name.trimmingCharacters(in: .whitespaces),
                type: type.rawValue,
                vintage: Int(vintage),
                country: country.isEmpty ? nil : country,
                region: region.isEmpty ? nil : region,
                storage_location: storageLocation.rawValue,
                purchase_location: purchaseLocation.rawValue,
                purchase_location_other_text: purchaseLocation == .other ? purchaseLocationOtherText : nil,
                original_quantity: quantity,
                current_quantity: quantity,
                photo_url: photoURL
            )

            let insertedWine: Wine = try await SupabaseService.client
                .from("wine")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            let validVarieties = grapeVarieties
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if !validVarieties.isEmpty {
                let varietyPayload = validVarieties.map {
                    GrapeVarietyPayload(wine_id: insertedWine.id, name: $0)
                }
                try await SupabaseService.client
                    .from("grape_variety")
                    .insert(varietyPayload)
                    .execute()
            }

            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}
