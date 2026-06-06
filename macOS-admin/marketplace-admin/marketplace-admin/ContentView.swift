import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case products = "Products"
    case orders = "Orders"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .products: return "shippingbox"
        case .orders: return "list.clipboard"
        }
    }
}

@MainActor
struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var selection: SidebarItem? = .products

    var body: some View {
        if !isLoggedIn {
            LoginView { isLoggedIn = true }
                .onAppear {
                    APIClient.shared.loadSavedToken()
                    if APIClient.shared.hasToken { isLoggedIn = true }
                }
        } else {
            NavigationSplitView {
                List(SidebarItem.allCases, selection: $selection) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
                .navigationTitle("Marketplace")
                .navigationSplitViewColumnWidth(min: 160, ideal: 200)
                .safeAreaInset(edge: .bottom) {
                    Button {
                        APIClient.shared.clearToken()
                        isLoggedIn = false
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                }
            } detail: {
                switch selection {
                case .products: ProductsView()
                case .orders: OrdersView()
                case nil: Text("Select a section").foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
    }
}
