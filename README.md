# Node.js Express MongoDB Razorpay Marketplace

A marketplace backend built with Node.js, Express, MongoDB, and Razorpay payments. Designed to be paired with an iOS client app.

## Tech Stack

- **Node.js** + **Express** - server and routing
- **MongoDB Atlas** + **Mongoose** - database
- **Razorpay** - payment gateway (Indian market)
- **JWT** + **bcryptjs** - authentication
- **Jest** + **Supertest** - automated testing

## Getting Started

All commands run from the `backend/` directory.

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment

Create a `.env` file in `backend/`:

```
PORT=3000
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/marketplace
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
JWT_SECRET=your_jwt_secret
```

### 3. Run

```bash
npm run dev    # development with auto-restart
npm start      # production
```

### 4. Test

```bash
npm test                              # all tests
npx jest tests/auth.test.js --forceExit   # single file
```

## iOS Integration

Run `npm run dev`, then use `http://<your-mac-ip>:3000/api` as the base URL. Find your IP with `ipconfig getifaddr en0`. iPhone and Mac must be on the same WiFi.

## API Endpoints

### Auth
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/auth/register` | Public | Register (`role`: `buyer` or `seller`) |
| POST | `/api/auth/login` | Public | Login, returns JWT token |

All protected routes require `Authorization: Bearer <token>` header.

### Products
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/products` | Public | List all products |
| GET | `/api/products/:id` | Public | Get a product |
| POST | `/api/products` | Seller | Create a product |
| PUT | `/api/products/:id` | Seller | Update own product |
| DELETE | `/api/products/:id` | Seller | Delete own product |

### Orders
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/orders` | Buyer | Place an order |
| GET | `/api/orders/my` | Buyer | View my orders |
| GET | `/api/orders/seller` | Seller | View incoming orders |
| PATCH | `/api/orders/:id/status` | Seller | Update status (`shipped`, `delivered`) |

### Payments
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
4. iOS app calls `POST /api/payments/verify` with the 3 Razorpay fields - status becomes `paid`, stock decremented
5. Razorpay also calls `/api/payments/webhook` server-side as backup

### Order Status Flow

```
pending -> paid -> shipped -> delivered
                           -> refunded
        -> cancelled (payment failed via webhook)
```
