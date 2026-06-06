import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var currentUser: User? = nil

    var body: some View {
        Group {
            if isLoggedIn, let user = currentUser {
                MainTabView(user: user, onLogout: logout)
            } else {
                AuthView { user in
                    currentUser = user
                    isLoggedIn = true
                }
            }
        }
        .onAppear {
            APIClient.shared.loadSavedToken()
            if APIClient.shared.hasToken, let user = APIClient.shared.loadSavedUser() {
                currentUser = user
                isLoggedIn = true
            }
        }
    }

    private func logout() {
        APIClient.shared.clearToken()
        currentUser = nil
        isLoggedIn = false
    }
}

struct MainTabView: View {
    let user: User
    let onLogout: () -> Void

    var body: some View {
        TabView {
            ProductsView()
                .tabItem {
                    Label("Shop", systemImage: "storefront")
                }

            AccountView(user: user, onLogout: onLogout)
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
        }
        .tint(Color.brand)
    }
}

struct AccountView: View {
    let user: User
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.brand)
                                .frame(width: 80, height: 80)
                            Text(String(user.name.prefix(1)).uppercased())
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        VStack(spacing: 4) {
                            Text(user.name)
                                .font(.title3).fontWeight(.semibold)
                            if let email = user.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // Account info
                if let email = user.email {
                    Section("Personal Info") {
                        LabeledContent {
                            Text(email)
                                .foregroundStyle(.secondary)
                        } label: {
                            Label("Email", systemImage: "envelope")
                        }

                        LabeledContent {
                            Text("Buyer")
                                .foregroundStyle(.secondary)
                        } label: {
                            Label("Account Type", systemImage: "person.badge.shield.checkmark")
                        }
                    }
                }

                Section("Activity") {
                    NavigationLink(destination: MyOrdersView()) {
                        Label("Transactions", systemImage: "creditcard")
                    }
                }

                Section {
                    Button(role: .destructive, action: onLogout) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Account")
        }
    }
}
