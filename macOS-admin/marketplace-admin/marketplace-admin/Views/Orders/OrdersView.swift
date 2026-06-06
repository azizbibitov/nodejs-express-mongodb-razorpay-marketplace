import SwiftUI

@MainActor
struct OrdersView: View {
    @State private var orders: [Order] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Orders")
                        .font(.title2).fontWeight(.bold)
                    if !orders.isEmpty {
                        Text("\(orders.count) orders")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { Task { await loadOrders() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
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
            } else if orders.isEmpty {
                ContentUnavailableView(
                    "No Orders",
                    systemImage: "list.clipboard",
                    description: Text("Orders from buyers will appear here.")
                )
            } else {
                Table(orders) {
                    TableColumn("Product") { order in
                        Text(order.product?.name ?? "-")
                            .lineLimit(1)
                    }

                    TableColumn("Buyer") { order in
                        Text(order.buyer?.name ?? "-")
                    }

                    TableColumn("Qty") { order in
                        Text("\(order.quantity)").monospacedDigit()
                    }
                    .width(40)

                    TableColumn("Amount") { order in
                        Text(String(format: "$%.2f", order.totalAmount))
                            .monospacedDigit()
                    }

                    TableColumn("Status") { order in
                        StatusBadge(status: order.status)
                    }

                    TableColumn("Actions") { order in
                        HStack(spacing: 6) {
                            if order.status == "paid" {
                                Button("Ship") { updateStatus(order, status: "shipped") }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(.purple)

                                Button("Refund") { refund(order) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(.red)
                            }
                            if order.status == "shipped" {
                                Button("Deliver") { updateStatus(order, status: "delivered") }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(.green)
                            }
                        }
                    }
                    .width(140)
                }
            }
        }
        .task { await loadOrders() }
    }

    private func loadOrders() async {
        isLoading = true
        errorMessage = ""
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

private struct StatusBadge: View {
    let status: String

    private var config: (color: Color, icon: String) {
        switch status {
        case "pending":   return (.orange, "clock")
        case "paid":      return (.blue, "creditcard")
        case "shipped":   return (.purple, "shippingbox")
        case "delivered": return (.green, "checkmark.circle")
        case "cancelled": return (.red, "xmark.circle")
        case "refunded":  return (.gray, "arrow.uturn.left")
        default:          return (.secondary, "questionmark")
        }
    }

    var body: some View {
        Label(status.capitalized, systemImage: config.icon)
            .font(.caption).fontWeight(.medium)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(config.color.opacity(0.12))
            .foregroundStyle(config.color)
            .clipShape(Capsule())
    }
}
