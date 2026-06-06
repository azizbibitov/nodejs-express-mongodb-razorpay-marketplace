import SwiftUI

struct ProductDetailView: View {
    let product: Product

    @State private var quantity = 1
    @State private var isOrdering = false
    @State private var errorMessage = ""
    @State private var createdOrder: CreatedOrder? = nil
    @State private var showingPayment = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Images pager
                if product.images.isEmpty {
                    Color(.systemGray5)
                        .frame(height: 300)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                        }
                } else {
                    TabView {
                        ForEach(product.images) { img in
                            AsyncImage(url: URL(string: img.url)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color(.systemGray5)
                            }
                            .clipped()
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 300)
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(product.category.uppercased())
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Color.brand)
                            .tracking(1)
                        Text(product.name)
                            .font(.title2).fontWeight(.bold)
                        Text(String(format: "₹%.2f", product.price))
                            .font(.title3).fontWeight(.semibold)
                            .foregroundStyle(Color.brand)
                    }

                    // Stock badge
                    stockBadge

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline).fontWeight(.semibold)
                        Text(product.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Quantity
                    if product.stock > 0 {
                        HStack {
                            Text("Quantity")
                                .font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Stepper("\(quantity)", value: $quantity, in: 1...min(product.stock, 10))
                                .fixedSize()
                        }
                    }

                    if !errorMessage.isEmpty {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // Buy button
                    Button(action: placeOrder) {
                        Group {
                            if isOrdering {
                                ProgressView().tint(.white)
                            } else {
                                Text(product.stock == 0 ? "Out of Stock" : "Buy Now - ₹\(String(format: "%.2f", product.price * Double(quantity)))")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brand)
                    .disabled(isOrdering || product.stock == 0)
                }
                .padding(20)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPayment) {
            if let order = createdOrder {
                PaymentView(order: order, productName: product.name) {
                    showingPayment = false
                }
            }
        }
    }

    @ViewBuilder
    private var stockBadge: some View {
        if product.stock == 0 {
            Label("Out of stock", systemImage: "xmark.circle")
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        } else if product.stock < 5 {
            Label("Only \(product.stock) left", systemImage: "exclamationmark.circle")
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        } else {
            Label("In stock", systemImage: "checkmark.circle")
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.green.opacity(0.1))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        }
    }

    private func placeOrder() {
        isOrdering = true
        errorMessage = ""
        Task {
            do {
                let order = try await APIClient.shared.createOrder(productId: product.id, quantity: quantity)
                createdOrder = order
                showingPayment = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isOrdering = false
        }
    }
}
