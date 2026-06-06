import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL = "http://192.168.1.109:3000/api"
    private var token: String?

    func setToken(_ token: String) {
        self.token = token
        KeychainManager.saveToken(token)
    }

    func loadSavedToken() {
        self.token = KeychainManager.loadToken()
    }

    func clearToken() {
        self.token = nil
        KeychainManager.deleteToken()
    }

    var hasToken: Bool { token != nil }

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        return try await post("/auth/register", body: ["name": name, "email": email, "password": password, "role": "buyer"])
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        return try await post("/auth/login", body: ["email": email, "password": password])
    }

    // MARK: - Products

    func getProducts() async throws -> [Product] {
        return try await get("/products")
    }

    // MARK: - Orders

    func createOrder(productId: String, quantity: Int) async throws -> CreatedOrder {
        return try await post("/orders", body: ["productId": productId, "quantity": quantity])
    }

    func getMyOrders() async throws -> [Order] {
        return try await get("/orders/my")
    }

    // MARK: - Payments

    func createRazorpayOrder(orderId: String) async throws -> RazorpayOrderResponse {
        return try await post("/payments/create", body: ["orderId": orderId])
    }

    func testPay(orderId: String) async throws {
        let _: [String: String] = try await post("/payments/test-pay", body: ["orderId": orderId])
    }

    func verifyPayment(orderId: String, razorpayOrderId: String, razorpayPaymentId: String, razorpaySignature: String) async throws {
        let body: [String: Any] = [
            "orderId": orderId,
            "razorpayOrderId": razorpayOrderId,
            "razorpayPaymentId": razorpayPaymentId,
            "razorpaySignature": razorpaySignature,
        ]
        let _: [String: String] = try await post("/payments/verify", body: body)
    }

    // MARK: - HTTP helpers

    private func request(_ path: String, method: String, body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
        print("[API] \(method) \(path)")
        let (data, response) = try await URLSession.shared.data(for: req)
        let http = response as? HTTPURLResponse
        print("[API] \(method) \(path) -> \(http?.statusCode ?? -1)")
        guard let http, (200...299).contains(http.statusCode) else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["message"] ?? "Unknown error"
            print("[API] Error: \(msg)")
            throw NSError(domain: "API", code: http?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        print("[API] Response: \(String(data: data, encoding: .utf8) ?? "")")
        return data
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await request(path, method: "GET")
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let data = try await request(path, method: "POST", body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
