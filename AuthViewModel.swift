import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var userEmail: String?

    init() {
        Task { await checkExistingSession() }
        Task { await listenForAuthChanges() }
    }

    private func checkExistingSession() async {
        if let session = try? await SupabaseService.client.auth.session {
            isAuthenticated = true
            userEmail = session.user.email
        }
        isLoading = false
    }

    private func listenForAuthChanges() async {
        for await state in SupabaseService.client.auth.authStateChanges {
            switch state.event {
            case .signedIn, .initialSession:
                isAuthenticated = state.session != nil
                userEmail = state.session?.user.email
            case .signedOut:
                isAuthenticated = false
                userEmail = nil
            default:
                break
            }
        }
    }

    /// Gibt true zurück bei Erfolg. Bei aktivierter E-Mail-Bestätigung muss der Nutzer
    /// danach noch seine E-Mail bestätigen, bevor Sign In funktioniert.
    func signUp(email: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            try await SupabaseService.client.auth.signUp(email: email, password: password)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signIn(email: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            try await SupabaseService.client.auth.signIn(email: email, password: password)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signOut() async {
        try? await SupabaseService.client.auth.signOut()
    }

    /// Ändert das Passwort des aktuell eingeloggten Nutzers. Gibt true zurück bei Erfolg.
    func updatePassword(newPassword: String) async -> Bool {
        errorMessage = nil
        do {
            try await SupabaseService.client.auth.update(user: UserAttributes(password: newPassword))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
