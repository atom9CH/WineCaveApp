import Foundation
import Combine
import Supabase

@MainActor
final class WineDetailViewModel: ObservableObject {
    let wineId: UUID

    @Published var name = ""
    @Published var type: WineType = .red
    @Published var vintage = ""
    @Published var country = ""
    @Published var region = ""
    @Published var storageLocation: StorageLocation = .cellar
    @Published var purchaseLocation: PurchaseLocation = .denner
    @Published var purchaseLocationOtherText = ""
    @Published var currentQuantity = 1
    @Published var grapeVarieties: [String] = [""]
    @Published var tastings: [Tasting] = []

    @Published var isSaving = false
    @Published var errorMessage: String?

    init(wine: Wine) {
        self.wineId = wine.id
        self.name = wine.name
        self.type = wine.type ?? .red
        self.vintage = wine.vintage.map(String.init) ?? ""
        self.country = wine.country ?? ""
        self.region = wine.region ?? ""
        self.storageLocation = wine.storageLocation ?? .cellar
        self.purchaseLocation = wine.purchaseLocation ?? .denner
        self.purchaseLocationOtherText = wine.purchaseLocationOtherText ?? ""
        self.currentQuantity = wine.currentQuantity
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func loadGrapeVarieties() async {
        do {
            let result: [GrapeVariety] = try await SupabaseService.client
                .from("grape_variety")
                .select()
                .eq("wine_id", value: wineId)
                .execute()
                .value
            let names = result.map { $0.name }
            grapeVarieties = names.isEmpty ? [""] : names
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTastings() async {
        do {
            tastings = try await SupabaseService.client
                .from("tasting")
                .select()
                .eq("wine_id", value: wineId)
                .order("tasted_at", ascending: false)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Nach dem Trinken einer Flasche: Menge + Historie neu laden
    func reloadAfterDrink() async {
        await loadTastings()
        do {
            let refreshed: Wine = try await SupabaseService.client
                .from("wine")
                .select()
                .eq("id", value: wineId)
                .single()
                .execute()
                .value
            currentQuantity = refreshed.currentQuantity
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private struct WineUpdatePayload: Encodable {
        let name: String
        let type: String
        let vintage: Int?
        let country: String?
        let region: String?
        let storage_location: String
        let purchase_location: String
        let purchase_location_other_text: String?
        let current_quantity: Int
    }

    private struct GrapeVarietyPayload: Encodable {
        let wine_id: UUID
        let name: String
    }

    func save() async -> Bool {
        guard isValid else { return false }
        isSaving = true
        errorMessage = nil

        let payload = WineUpdatePayload(
            name: name.trimmingCharacters(in: .whitespaces),
            type: type.rawValue,
            vintage: Int(vintage),
            country: country.isEmpty ? nil : country,
            region: region.isEmpty ? nil : region,
            storage_location: storageLocation.rawValue,
            purchase_location: purchaseLocation.rawValue,
            purchase_location_other_text: purchaseLocation == .other ? purchaseLocationOtherText : nil,
            current_quantity: currentQuantity
        )

        do {
            try await SupabaseService.client
                .from("wine")
                .update(payload)
                .eq("id", value: wineId)
                .execute()

            // Simplest approach: replace all grape varieties on save
            try await SupabaseService.client
                .from("grape_variety")
                .delete()
                .eq("wine_id", value: wineId)
                .execute()

            let validVarieties = grapeVarieties
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if !validVarieties.isEmpty {
                let varietyPayload = validVarieties.map {
                    GrapeVarietyPayload(wine_id: wineId, name: $0)
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

    func delete() async -> Bool {
        isSaving = true
        errorMessage = nil
        do {
            try await SupabaseService.client
                .from("wine")
                .delete()
                .eq("id", value: wineId)
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
