import SwiftUI

struct MyOrdersView: View {
    @State private var orders: [Order] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !errorMessage.isEmpty {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else if orders.isEmpty {
                    ContentUnavailableView(
                        "No Orders Yet",
                        systemImage: "bag",
                        description: Text("Browse the shop and place your first order.")
                    )
                } else {
                    List(orders) { order in
                        OrderRow(order: order)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Orders")
            .task { await loadOrders() }
            .refreshable { await loadOrders() }
        }
    }

    private func loadOrders() async {
        isLoading = orders.isEmpty
        do {
            orders = try await APIClient.shared.getMyOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack(spacing: 14) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(order.product?.name ?? "Product")
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(statusLabel)
                        .font(.caption).fontWeight(.medium)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(statusColor.opacity(0.1))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())

                    Text("Qty: \(order.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(String(format: "₹%.2f", order.totalAmount))
                .font(.subheadline).fontWeight(.bold)
                .foregroundStyle(Color.brand)
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch order.status {
        case "pending":   return .orange
        case "paid":      return .blue
        case "shipped":   return .purple
        case "delivered": return .green
        case "cancelled": return .red
        case "refunded":  return .gray
        default:          return .secondary
        }
    }

    private var statusIcon: String {
        switch order.status {
        case "pending":   return "clock"
        case "paid":      return "creditcard"
        case "shipped":   return "shippingbox"
        case "delivered": return "checkmark.circle.fill"
        case "cancelled": return "xmark.circle"
        case "refunded":  return "arrow.uturn.left"
        default:          return "questionmark"
        }
    }

    private var statusLabel: String { order.status.capitalized }

    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: order.createdAt) else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
