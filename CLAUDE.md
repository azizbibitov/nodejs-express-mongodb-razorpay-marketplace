# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Three separate projects in one repo:

- `backend/` - Node.js/Express API
- `iOS-client/` - SwiftUI iOS buyer app
- `macOS-admin/` - SwiftUI macOS admin app

## Backend Commands

All commands from `backend/` directory:

```bash
npm run dev      # start with nodemon (auto-restart)
npm start        # production
npm test         # all 25 Jest tests
npx jest tests/auth.test.js --forceExit   # single file
```

## Backend Environment

`backend/.env` requires:

```
PORT=3000
MONGO_URI=...marketplace database...
TEST_MONGO_URI=...marketplace-test database...
RAZORPAY_KEY_ID=...
RAZORPAY_KEY_SECRET=...
RAZORPAY_WEBHOOK_SECRET=...
JWT_SECRET=...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```

`TEST_MONGO_URI` points to a separate `marketplace-test` database so tests never touch real data.

## Backend Architecture

`app.js` configures Express and registers routes. `server.js` connects to MongoDB and starts the listener. Tests import `app.js` directly via Supertest - never `server.js`.

3-tier structure per feature:
- `models/` - Mongoose schema (Data tier)
- `controllers/` - business logic (Service tier)
- `routes/` - Express router wiring (Web tier)
- `middleware/auth.js` - JWT verification, sets `req.user = { id, role }`
- `middleware/upload.js` - multer, memory storage, 5MB image limit

## Image Upload Flow

`POST /api/upload/image` accepts `multipart/form-data` with field `image`. Multer stores file in memory as a Buffer, then `uploadController.js` streams it to Cloudinary via `upload_stream`. Returns `{ url }`. The URL is stored in `Product.images[]`.

Cloudinary mock in tests: `jest.mock('cloudinary')` in `upload.test.js`.

## Payment Flow

Razorpay amounts are always in **paise** (INR × 100).

1. `POST /api/payments/create` - creates Razorpay order, stores `razorpayOrderId` on Order
2. iOS Razorpay SDK shows payment UI
3. `POST /api/payments/verify` - verifies HMAC-SHA256 of `razorpayOrderId|razorpayPaymentId`, marks order `paid`, decrements stock

`POST /api/payments/webhook` uses `express.raw()` (registered before `express.json()` in `app.js`) because signature verification needs raw Buffer body.

## Order Status Flow

```
pending -> paid -> shipped -> delivered
                           -> refunded
        -> cancelled (payment failed)
```

## Testing

Tests use `TEST_MONGO_URI` (separate DB). `setup.js` wipes all collections before and after each suite. Razorpay and Cloudinary are mocked - no real API calls in tests. Tests run sequentially (`--runInBand`).

## macOS Admin App

Located in `macOS-admin/marketplace-admin/marketplace-admin/`.

- `Network/APIClient.swift` - all HTTP calls, `multipart/form-data` upload, debug logging
- `Network/Models.swift` - `User`, `Product`, `Order`, `AuthResponse` Codable structs
- `Network/KeychainManager.swift` - JWT token persistence across app restarts
- `Views/Login/` - `LoginView.swift`
- `Views/Products/` - `ProductsView.swift`, `ProductFormView.swift`
- `Views/Orders/` - `OrdersView.swift`

All views are `@MainActor` to prevent threading crashes. Uses `.fileImporter()` for image picking (not `NSOpenPanel.runModal()` which blocks the main thread and resets SwiftUI state).

`User.id` maps from `_id` in JSON via `CodingKeys`. Auth response and MongoDB documents both use `_id`.

## Local Development

Run backend with `npm run dev`, use `http://<mac-ip>:3000/api` as base URL in Swift. Find IP with `ipconfig getifaddr en0`. Mac and iPhone/device must be on same WiFi.
