import Foundation
import Supabase

enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: Secrets.supabaseURL,
        supabaseKey: Secrets.supabaseAnonKey
    )

    /// ID des aktuell eingeloggten Nutzers, falls vorhanden. Wird beim Speichern
    /// neuer Datensätze (Wein, Rebsorte, Tasting) als "user_id" mitgeschickt.
    static var currentUserId: UUID? {
        client.auth.currentSession?.user.id
    }
}
