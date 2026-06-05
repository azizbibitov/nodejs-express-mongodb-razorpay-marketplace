# Marketplace - Node.js + iOS + macOS

A full marketplace project with three components:

- `backend/` - Node.js/Express/MongoDB REST API
- `iOS-client/` - SwiftUI iOS buyer app
- `macOS-admin/` - SwiftUI macOS admin app for sellers

---

## Backend

### Tech Stack

- **Node.js** + **Express** - server and routing
- **MongoDB Atlas** + **Mongoose** - database
- **Razorpay** - payment gateway (Indian market)
- **Cloudinary** - image storage
- **JWT** + **bcryptjs** - authentication
- **Jest** + **Supertest** - automated testing (25 tests)

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
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/marketplace
TEST_MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/marketplace-test
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### API Endpoints

All protected routes require `Authorization: Bearer <token>` header.

#### Auth
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/auth/register` | Public | Register (`role`: `buyer` or `seller`) |
| POST | `/api/auth/login` | Public | Login, returns JWT token |

#### Products
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/products` | Public | List all products |
| GET | `/api/products/:id` | Public | Get a product |
| POST | `/api/products` | Seller | Create a product |
| PUT | `/api/products/:id` | Seller | Update own product |
| DELETE | `/api/products/:id` | Seller | Delete own product |

#### Upload
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/upload/image` | Seller | Upload image to Cloudinary, returns URL |

#### Orders
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/orders` | Buyer | Place an order |
| GET | `/api/orders/my` | Buyer | View my orders |
| GET | `/api/orders/seller` | Seller | View incoming orders |
| PATCH | `/api/orders/:id/status` | Seller | Update status (`shipped`, `delivered`) |

#### Payments
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/payments/create` | Buyer | Create Razorpay order for an order ID |
| POST | `/api/payments/verify` | Buyer | Verify payment signature, marks order as paid |
| POST | `/api/payments/webhook` | Razorpay | Webhook for payment events (no auth) |
| POST | `/api/payments/refund/:orderId` | Seller | Refund a paid order |

### Payment Flow

1. Buyer places order (`POST /api/orders`) - status: `pending`
2. Buyer calls `POST /api/payments/create` with `orderId` - gets back `razorpayOrderId`
3. iOS Razorpay SDK collects payment using that order ID
4. iOS app calls `POST /api/payments/verify` with 3 Razorpay fields - status becomes `paid`, stock decremented
5. Razorpay calls `/api/payments/webhook` server-side as backup

### Order Status Flow

```
pending -> paid -> shipped -> delivered
                           -> refunded
        -> cancelled (payment failed via webhook)
```

---

## macOS Admin App

SwiftUI app for sellers to manage the marketplace.

**Features:** Login, product list/create/edit/delete with image upload, order management, refunds.

**Auth:** JWT token persisted in Keychain - stays logged in across app restarts.

**Base URL:** Set `baseURL` in `APIClient.swift` to your server IP.

---

## iOS Integration

Run `npm run dev`, then use `http://<mac-ip>:3000/api` as base URL. Find your IP with `ipconfig getifaddr en0`. iPhone and Mac must be on the same WiFi.
