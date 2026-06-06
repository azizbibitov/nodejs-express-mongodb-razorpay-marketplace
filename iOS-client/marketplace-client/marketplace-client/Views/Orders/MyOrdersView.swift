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
                        "No Transactions",
                        systemImage: "creditcard",
                        description: Text("Your payment history will appear here.")
                    )
                } else {
                    List {
                        ForEach(groupedByMonth, id: \.month) { section in
                            Section(section.month) {
                                ForEach(section.orders) { order in
                                    TransactionRow(order: order)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Transactions")
            .task { await loadOrders() }
            .refreshable { await loadOrders() }
        }
    }

    private var groupedByMonth: [(month: String, orders: [Order])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var groups: [(month: String, orders: [Order])] = []
        var seen: [String: Int] = [:]

        for order in orders {
            let date = iso.date(from: order.createdAt) ?? Date()
            let month = formatter.string(from: date)
            if let idx = seen[month] {
                groups[idx].orders.append(order)
            } else {
                seen[month] = groups.count
                groups.append((month: month, orders: [order]))
            }
        }
        return groups
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

private struct TransactionRow: View {
    let order: Order

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.system(size: 19))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(order.product?.name ?? "Unknown Product")
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(statusLabel)
                        .font(.caption).fontWeight(.medium)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())

                    Text("Qty \(order.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let txId = order.razorpayPaymentId {
                    Text(txId)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", order.totalAmount))
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(amountColor)
                    .strikethrough(order.status == "refunded", color: .gray)

                if order.status == "refunded" {
                    Text("Refunded")
                        .font(.caption2).fontWeight(.medium)
                        .foregroundStyle(.gray)
                }
            }
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
        case "paid":      return "checkmark.circle.fill"
        case "shipped":   return "shippingbox.fill"
        case "delivered": return "bag.fill.badge.checkmark"
        case "cancelled": return "xmark.circle.fill"
        case "refunded":  return "arrow.uturn.left.circle.fill"
        default:          return "questionmark.circle"
        }
    }

    private var statusLabel: String { order.status.capitalized }

    private var amountColor: Color {
        switch order.status {
        case "refunded":  return .gray
        case "cancelled": return .red
        default:          return Color.brand
        }
    }

    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: order.createdAt) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
