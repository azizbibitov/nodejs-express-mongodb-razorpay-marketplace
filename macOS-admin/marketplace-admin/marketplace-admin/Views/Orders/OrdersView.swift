import SwiftUI

struct OrdersView: View {
    @State private var orders: [Order] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Orders")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red).padding()
            } else {
                Table(orders) {
                    TableColumn("Product") { order in
                        Text(order.product?.name ?? "-")
                    }
                    TableColumn("Buyer") { order in
                        Text(order.buyer?.name ?? "-")
                    }
                    TableColumn("Qty") { order in
                        Text("\(order.quantity)")
                    }
                    TableColumn("Amount") { order in
                        Text(String(format: "₹%.2f", order.totalAmount))
                    }
                    TableColumn("Status", value: \.status)
                    TableColumn("Actions") { order in
                        HStack {
                            if order.status == "paid" {
                                Button("Ship") { updateStatus(order, status: "shipped") }
                                Button("Refund") { refund(order) }
                                    .foregroundColor(.red)
                            }
                            if order.status == "shipped" {
                                Button("Deliver") { updateStatus(order, status: "delivered") }
                            }
                        }
                    }
                }
            }
        }
        .task { await loadOrders() }
    }

    private func loadOrders() async {
        isLoading = true
        do {
            orders = try await APIClient.shared.getSellerOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func updateStatus(_ order: Order, status: String) {
        Task {
            do {
                _ = try await APIClient.shared.updateOrderStatus(id: order.id, status: status)
                await loadOrders()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refund(_ order: Order) {
        Task {
            do {
                try await APIClient.shared.refundOrder(id: order.id)
                await loadOrders()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
