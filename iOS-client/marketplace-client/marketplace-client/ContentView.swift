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
            // Token exists but we don't have user info cached - will re-login
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

            MyOrdersView()
                .tabItem {
                    Label("My Orders", systemImage: "bag")
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
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.12))
                                .frame(width: 52, height: 52)
                            Text(String(user.name.prefix(1)).uppercased())
                                .font(.title2).fontWeight(.semibold)
                                .foregroundStyle(Color.brand)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name).font(.headline)
                            if let email = user.email {
                                Text(email).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(role: .destructive, action: onLogout) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Account")
        }
    }
}
