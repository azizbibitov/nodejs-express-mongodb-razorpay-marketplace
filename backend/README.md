# Node.js Express MongoDB Razorpay Marketplace

A marketplace backend built with Node.js, Express, MongoDB, and Razorpay payments.

## Tech Stack

- **Node.js** + **Express** - server and routing
- **MongoDB** + **Mongoose** - database
- **Razorpay** - payment gateway
- **JWT** + **bcryptjs** - authentication
- **Jest** + **Supertest** - testing

## Features

- User auth (register, login, JWT)
- Sellers can list products
- Buyers can browse and order products
- Razorpay payment integration (create order, verify, webhook, refund)

## Getting Started

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment

Create a `.env` file:

```
PORT=3000
MONGO_URI=your_mongodb_atlas_uri
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
JWT_SECRET=your_jwt_secret
```

### 3. Run

```bash
npm run dev
```

### 4. Test

```bash
npm test
```

## API Endpoints

### Auth
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/auth/register` | Public | Register a new user |
| POST | `/api/auth/login` | Public | Login and get token |

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
| PATCH | `/api/orders/:id/status` | Seller | Update order status |

### Payments
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/payments/create` | Buyer | Create Razorpay order |
| POST | `/api/payments/verify` | Buyer | Verify payment signature |
| POST | `/api/payments/webhook` | Razorpay | Handle payment events |
| POST | `/api/payments/refund` | Seller | Refund a payment |

## Project Structure

```
src/
  app.js              - Express app setup
  server.js           - DB connection and server start
  routes/             - Route definitions
  controllers/        - Business logic
  models/             - Mongoose schemas
  middleware/         - Auth middleware
tests/                - Jest test suites
```
