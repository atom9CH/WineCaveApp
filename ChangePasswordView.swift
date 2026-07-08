import SwiftUI

struct ChangePasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var successMessage: String?
    @State private var localError: String?

    private var validationError: String? {
        if newPassword.isEmpty || confirmPassword.isEmpty { return nil }
        if newPassword.count < 6 { return "Password must be at least 6 characters." }
        if newPassword != confirmPassword { return "Passwords don't match." }
        return nil
    }

    private var canSave: Bool {
        !newPassword.isEmpty && !confirmPassword.isEmpty && validationError == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New password", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                } footer: {
                    Text("At least 6 characters.")
                }

                if let error = validationError ?? localError ?? authViewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                if let successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .disabled(isSaving)
        }
    }

    private func save() async {
        isSaving = true
        localError = nil
        successMessage = nil
        if await authViewModel.updatePassword(newPassword: newPassword) {
            successMessage = "Password updated."
            newPassword = ""
            confirmPassword = ""
            try? await Task.sleep(nanoseconds: 800_000_000)
            dismiss()
        }
        isSaving = false
    }
}
