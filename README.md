# Marketplace - Node.js + iOS + macOS

A full-stack marketplace with three components:

- `backend/` - Node.js/Express/MongoDB REST API
- `iOS-client/` - SwiftUI iOS buyer app
- `macOS-admin/` - SwiftUI macOS admin app for sellers

---

## Backend

### Tech Stack

- **Node.js** + **Express** - server and routing
- **MongoDB Atlas** + **Mongoose** - database
- **Razorpay** - payment gateway
- **Cloudinary** - image storage (repository pattern via `ImageStorage` base class)
- **JWT** + **bcryptjs** - authentication
- **Jest** + **Supertest** - 25 automated tests

### Getting Started

All commands run from the `backend/` directory.

```bash
npm install
npm run dev      # development with auto-restart
npm start        # production
npm test         # run all tests
npx jest tests/auth.test.js --forceExit   # single test file
```

### Environment

Create `backend/.env`:

```
PORT=3000
MONGO_URI=mongodb+srv://...marketplace
TEST_MONGO_URI=mongodb+srv://...marketplace-test
RAZORPAY_KEY_ID=...
RAZORPAY_KEY_SECRET=...
RAZORPAY_WEBHOOK_SECRET=...
JWT_SECRET=...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```

`TEST_MONGO_URI` must point to a separate database - tests wipe all collections before and after each suite.

### API Endpoints

All protected routes require `Authorization: Bearer <token>`.

#### Auth
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/auth/register` | Public | Register (`role`: `buyer` or `seller`) |
| POST | `/api/auth/login` | Public | Login, returns JWT |

#### Products
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/products` | Public | List all products |
| GET | `/api/products/:id` | Public | Get single product |
| POST | `/api/products` | Seller | Create product |
| PUT | `/api/products/:id` | Seller | Update own product |
| DELETE | `/api/products/:id` | Seller | Delete own product (also removes Cloudinary images) |

#### Upload
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/upload/image` | Seller | Upload image, returns `{ url, publicId }` |

#### Orders
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/orders` | Buyer | Place an order |
| GET | `/api/orders/my` | Buyer | My orders (product populated) |
| GET | `/api/orders/seller` | Seller | Incoming orders (buyer + product populated) |
| PATCH | `/api/orders/:id/status` | Seller | Update status (`shipped`, `delivered`) |

#### Payments
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/payments/create` | Buyer | Create Razorpay order for an order |
| POST | `/api/payments/verify` | Buyer | Verify HMAC signature, marks order `paid`, decrements stock |
| POST | `/api/payments/webhook` | Razorpay | Webhook for payment events (raw body, no auth) |
| POST | `/api/payments/refund/:orderId` | Seller | Refund a paid order |
| POST | `/api/payments/test-pay` | Buyer | Dev only - simulate payment without Razorpay SDK |

### Payment Flow

1. Buyer places order (`POST /api/orders`) - status: `pending`
2. Buyer calls `POST /api/payments/create` with `orderId` - gets `razorpayOrderId`, `amount`, `currency`
3. iOS Razorpay SDK collects payment
4. iOS calls `POST /api/payments/verify` with signature - status becomes `paid`, stock decremented
5. Razorpay calls `/api/payments/webhook` as server-side backup

**Dev mode:** `POST /api/payments/test-pay` skips the SDK entirely. Blocked in production.

### Order Status Flow

```
pending -> paid -> shipped -> delivered
                           -> refunded (seller-initiated)
        -> cancelled (payment failed via webhook)
```

### Image Storage

`Product.images` is `[{ url, publicId }]`. On product delete or image removal during edit, `publicId` is used to delete from Cloudinary. The `ImageStorage` base class in `src/storage/` allows swapping providers without changing controllers.

---

## iOS Buyer App (`iOS-client/`)

SwiftUI app for buyers.

**Features:**
- Browse products in a 2-column grid with search and pull-to-refresh
- Product detail with image carousel, stock badge, quantity stepper, pinned Buy button
- Payment flow with dev "Simulate Payment" button (calls `test-pay`) and Razorpay SDK placeholder
- Transaction history in Account tab showing all orders grouped by month, with payment IDs, refunded status (strikethrough), and time
- Session persistence - JWT in Keychain, user info in UserDefaults, stays logged in across restarts

**Base URL:** Set `baseURL` in `Network/APIClient.swift` to `http://<mac-ip>:3000/api`.

---

## macOS Admin App (`macOS-admin/`)

SwiftUI app for sellers.

**Features:**
- Login with JWT persisted in Keychain
- Product list with stock badges, edit/delete, image upload via `.fileImporter()`
- Orders table with status badges, Ship/Deliver/Refund actions, pull-to-refresh
- All views are `@MainActor`

**Base URL:** Set `baseURL` in `Network/APIClient.swift` to `http://<mac-ip>:3000/api`.

---

## Local Development

```bash
# Find your Mac's local IP
ipconfig getifaddr en0

# Start backend
cd backend && npm run dev
```

Mac and iPhone must be on the same WiFi. Use the IP above as the base URL in both Swift apps.
