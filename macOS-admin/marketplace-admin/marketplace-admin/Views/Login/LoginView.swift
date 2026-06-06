import SwiftUI

@MainActor
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    var onLogin: () -> Void

    var body: some View {
        ZStack {
            Color(NSColor.underPageBackgroundColor).ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.brand)
                            .frame(width: 64, height: 64)
                        Image(systemName: "storefront")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 4) {
                        Text("Marketplace Admin")
                            .font(.title2).fontWeight(.bold)
                        Text("Manage your store")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 10) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(spacing: 12) {
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: login) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Text("Sign In").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brand)
                    .controlSize(.large)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
            }
            .padding(36)
            .frame(width: 340)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
        }
        .frame(width: 520, height: 420)
    }

    private func login() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                let response = try await APIClient.shared.login(email: email, password: password)
                APIClient.shared.setToken(response.token)
                onLogin()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
