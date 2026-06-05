import SwiftUI

@MainActor
struct ProductsView: View {
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingForm = false
    @State private var selectedProduct: Product? = nil

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Products")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Add Product") { showingForm = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red).padding()
            } else {
                Table(products) {
                    TableColumn("Name", value: \.name)
                    TableColumn("Category", value: \.category)
                    TableColumn("Price") { product in
                        Text(String(format: "₹%.2f", product.price))
                    }
                    TableColumn("Stock") { product in
                        Text("\(product.stock)")
                    }
                    TableColumn("Actions") { product in
                        HStack {
                            Button("Edit") { selectedProduct = product }
                            Button("Delete") { deleteProduct(product) }
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .task { await loadProducts() }
        .sheet(isPresented: $showingForm) {
            ProductFormView(product: nil) { await loadProducts() }
        }
        .sheet(item: $selectedProduct) { product in
            ProductFormView(product: product) { await loadProducts() }
        }
    }

    private func loadProducts() async {
        isLoading = true
        do {
            products = try await APIClient.shared.getProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteProduct(_ product: Product) {
        Task {
            do {
                try await APIClient.shared.deleteProduct(id: product.id)
                await loadProducts()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
