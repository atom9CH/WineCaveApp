import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var isSubmitting = false
    @State private var infoMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)
                    Text("Wine Cellar")
                        .font(.system(size: 28, weight: .bold))
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    SecureField("Password", text: $password)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 24)

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }

                if let infoMessage {
                    Text(infoMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUpMode ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .disabled(email.isEmpty || password.isEmpty || isSubmitting)

                Button {
                    isSignUpMode.toggle()
                    authViewModel.errorMessage = nil
                    infoMessage = nil
                } label: {
                    Text(isSignUpMode ? "Already have an account? Sign In" : "No account yet? Sign Up")
                        .font(.footnote)
                }

                Spacer()
                Spacer()
            }
            .background(Color("AppBackground"))
        }
    }

    private func submit() async {
        isSubmitting = true
        infoMessage = nil
        if isSignUpMode {
            if await authViewModel.signUp(email: email, password: password) {
                infoMessage = "Account created. Check your email to confirm, then sign in."
                isSignUpMode = false
            }
        } else {
            _ = await authViewModel.signIn(email: email, password: password)
        }
        isSubmitting = false
    }
}
