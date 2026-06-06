import SwiftUI

@MainActor
struct ProductsView: View {
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingForm = false
    @State private var selectedProduct: Product? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Products")
                        .font(.title2).fontWeight(.bold)
                    if !products.isEmpty {
                        Text("\(products.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    showingForm = true
                } label: {
                    Label("Add Product", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !errorMessage.isEmpty {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if products.isEmpty {
                ContentUnavailableView(
                    "No Products",
                    systemImage: "shippingbox",
                    description: Text("Add your first product to get started.")
                )
            } else {
                Table(products) {
                    TableColumn("") { product in
                        if let imageURL = product.images.first.flatMap({ URL(string: $0.url) }) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color(NSColor.separatorColor)
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.quaternaryLabelColor))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                        }
                    }
                    .width(48)

                    TableColumn("Name", value: \.name)
                    TableColumn("Category", value: \.category)

                    TableColumn("Price") { product in
                        Text(String(format: "₹%.2f", product.price))
                            .monospacedDigit()
                    }

                    TableColumn("Stock") { product in
                        HStack(spacing: 6) {
                            Text("\(product.stock)").monospacedDigit()
                            if product.stock == 0 {
                                stockBadge("Out", color: .red)
                            } else if product.stock < 5 {
                                stockBadge("Low", color: .orange)
                            }
                        }
                    }

                    TableColumn("Actions") { product in
                        HStack(spacing: 6) {
                            Button { selectedProduct = product } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button(role: .destructive) { deleteProduct(product) } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                        }
                    }
                    .width(80)
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

    @ViewBuilder
    private func stockBadge(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption2).fontWeight(.medium)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func loadProducts() async {
        isLoading = true
        errorMessage = ""
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
