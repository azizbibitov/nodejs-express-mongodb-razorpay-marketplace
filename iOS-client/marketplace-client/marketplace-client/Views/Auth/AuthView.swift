import SwiftUI

struct AuthView: View {
    let onAuth: (User) -> Void

    @State private var isRegistering = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)

                    // Logo
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.brand)
                                .frame(width: 80, height: 80)
                            Image(systemName: "bag")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 4) {
                            Text("Marketplace")
                                .font(.title).fontWeight(.bold)
                            Text(isRegistering ? "Create your account" : "Welcome back")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Form card
                    VStack(spacing: 16) {
                        if isRegistering {
                            FormField(icon: "person", placeholder: "Full name", text: $name)
                        }
                        FormField(icon: "envelope", placeholder: "Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        FormField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)

                        if !errorMessage.isEmpty {
                            Label(errorMessage, systemImage: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: submit) {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isRegistering ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brand)
                        .disabled(isLoading || email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty))
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // Toggle
                    Button {
                        withAnimation {
                            isRegistering.toggle()
                            errorMessage = ""
                        }
                    } label: {
                        Group {
                            if isRegistering {
                                Text("Already have an account? ") + Text("Sign In").foregroundColor(Color.brand).fontWeight(.semibold)
                            } else {
                                Text("Don't have an account? ") + Text("Register").foregroundColor(Color.brand).fontWeight(.semibold)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func submit() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                let response: AuthResponse
                if isRegistering {
                    response = try await APIClient.shared.register(name: name, email: email, password: password)
                } else {
                    response = try await APIClient.shared.login(email: email, password: password)
                }
                APIClient.shared.setToken(response.token)
                APIClient.shared.saveUser(response.user)
                onAuth(response.user)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
