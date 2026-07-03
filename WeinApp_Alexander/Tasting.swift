import Foundation

struct Tasting: Identifiable, Codable {
    let id: UUID
    var wineId: UUID
    var rating: Int
    var note: String?
    var photoURL: String?
    var tastedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case wineId = "wine_id"
        case rating
        case note
        case photoURL = "photo_url"
        case tastedAt = "tasted_at"
    }
}
