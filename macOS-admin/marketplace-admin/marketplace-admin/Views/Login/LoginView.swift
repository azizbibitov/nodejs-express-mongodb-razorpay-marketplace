import SwiftUI

@MainActor
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    var onLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Marketplace Admin")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                        .frame(width: 100)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
        }
        .frame(width: 400, height: 300)
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
