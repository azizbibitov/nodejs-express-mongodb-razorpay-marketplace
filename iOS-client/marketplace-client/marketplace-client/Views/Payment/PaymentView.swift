import SwiftUI

struct PaymentView: View {
    let order: CreatedOrder
    let productName: String
    let onDismiss: () -> Void

    @State private var isProcessing = false
    @State private var errorMessage = ""
    @State private var isPaid = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isPaid {
                    successView
                } else {
                    paymentView
                }
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isPaid {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onDismiss() }
                    }
                }
            }
        }
    }

    private var paymentView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Order summary card
            VStack(spacing: 16) {
                Image(systemName: "creditcard")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.brand)

                VStack(spacing: 6) {
                    Text("Order Summary")
                        .font(.title3).fontWeight(.bold)
                    Text(productName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("Total Amount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", order.totalAmount))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(Color.brand)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            .padding(.horizontal, 20)

            if !errorMessage.isEmpty {
                Label(errorMessage, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
            }

            Spacer()

            VStack(spacing: 12) {
                // Pay button - integrates Razorpay SDK
                Button(action: startPayment) {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "lock.fill")
                            Text("Pay $\(String(format: "%.2f", order.totalAmount)) with Razorpay")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brand)
                .disabled(isProcessing)
                .padding(.horizontal, 20)

                Text("Secured by Razorpay")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Button("Simulate Payment (Dev Only)") {
                    simulatePayment()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .disabled(isProcessing)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.green)
                }

                VStack(spacing: 6) {
                    Text("Payment Successful!")
                        .font(.title2).fontWeight(.bold)
                    Text("Your order has been placed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Done") { onDismiss() }
                .buttonStyle(.borderedProminent)
                .tint(Color.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func simulatePayment() {
        isProcessing = true
        errorMessage = ""
        Task {
            do {
                try await APIClient.shared.testPay(orderId: order.id)
                isPaid = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    private func startPayment() {
        isProcessing = true
        errorMessage = ""
        Task {
            do {
                let razorpayOrder = try await APIClient.shared.createRazorpayOrder(orderId: order.id)

                // TODO: Integrate Razorpay iOS SDK
                // 1. Add package: https://github.com/razorpay/razorpay-swift-package-ios
                // 2. Import RazorpayCheckout
                // 3. Call the SDK with razorpayOrder.razorpayOrderId and your key_id
                // 4. On SDK success callback, call verifyPayment below:
                //
                // let options: [String: Any] = [
                //     "key": "YOUR_RAZORPAY_KEY_ID",
                //     "amount": razorpayOrder.amount,
                //     "currency": razorpayOrder.currency,
                //     "order_id": razorpayOrder.razorpayOrderId,
                // ]
                // RazorpayCheckout.open(options) { response in
                //     Task {
                //         try await APIClient.shared.verifyPayment(
                //             orderId: order.id,
                //             razorpayOrderId: razorpayOrder.razorpayOrderId,
                //             razorpayPaymentId: response["razorpay_payment_id"] as! String,
                //             razorpaySignature: response["razorpay_signature"] as! String
                //         )
                //         isPaid = true
                //     }
                // }

                // Placeholder until SDK is integrated:
                print("[Payment] Razorpay order created: \(razorpayOrder.razorpayOrderId)")
                errorMessage = "Razorpay SDK not yet integrated. Add the Swift package and your credentials to complete payments."
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
}
