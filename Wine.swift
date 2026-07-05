import Foundation

enum WineType: String, Codable, CaseIterable {
    case red
    case white
    case rose
    case sparkling

    var displayName: String {
        switch self {
        case .red: return "Red wine"
        case .white: return "White wine"
        case .rose: return "Rosé"
        case .sparkling: return "Sparkling wine"
        }
    }
}

enum StorageLocation: String, Codable, CaseIterable {
    case home
    case cellar
}

enum PurchaseLocation: String, Codable, CaseIterable {
    case denner
    case coop
    case aldi
    case lidl
    case ottos
    case other

    var displayName: String {
        switch self {
        case .denner: return "Denner"
        case .coop: return "Coop"
        case .aldi: return "Aldi"
        case .lidl: return "Lidl"
        case .ottos: return "Otto's"
        case .other: return "Other"
        }
    }
}

enum WineStatus: String, Codable {
    case available
    case depleted
}

struct Wine: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: WineType?
    var vintage: Int?
    var country: String?
    var region: String?
    var storageLocation: StorageLocation?
    var purchaseLocation: PurchaseLocation?
    var purchaseLocationOtherText: String?
    var photoURL: String?
    var originalQuantity: Int
    var currentQuantity: Int
    var status: WineStatus
    var createdAt: Date
    var updatedAt: Date
    /// Nur befüllt, wenn die Abfrage "tasting(rating)" mit-selektiert (siehe WineListViewModel)
    var tastings: [TastingRating]?
    /// Nur befüllt, wenn die Abfrage "grape_variety(name)" mit-selektiert (siehe WineSearchViewModel)
    var grapeVarietyNames: [GrapeVarietyEmbed]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case vintage
        case country
        case region
        case storageLocation = "storage_location"
        case purchaseLocation = "purchase_location"
        case purchaseLocationOtherText = "purchase_location_other_text"
        case photoURL = "photo_url"
        case originalQuantity = "original_quantity"
        case currentQuantity = "current_quantity"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tastings = "tasting"
        case grapeVarietyNames = "grape_variety"
    }

    var averageRating: Double? {
        let ratings = (tastings ?? []).compactMap { $0.rating }
        guard !ratings.isEmpty else { return nil }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
}

struct TastingRating: Codable {
    let rating: Int?
}

struct GrapeVariety: Identifiable, Codable {
    let id: UUID
    var wineId: UUID
    var name: String

    enum CodingKeys: String, CodingKey {
        case id
        case wineId = "wine_id"
        case name
    }
}
