# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All commands must be run from the `backend/` directory.

```bash
npm run dev      # start server with nodemon (auto-restart on file changes)
npm start        # start server without auto-restart
npm test         # run all Jest tests
```

Run a single test file:
```bash
npx jest tests/auth.test.js --forceExit
```

## Environment

Requires a `.env` file in `backend/`:

```
PORT=3000
MONGO_URI=mongodb+srv://...
RAZORPAY_KEY_ID=...
RAZORPAY_KEY_SECRET=...
RAZORPAY_WEBHOOK_SECRET=...
JWT_SECRET=...
```

## Architecture

`app.js` configures Express and registers routes. `server.js` connects to MongoDB and starts the listener. Tests import `app.js` directly via Supertest - never `server.js`.

3-tier structure per feature:
- `models/` - Mongoose schema (Data tier)
- `controllers/` - business logic (Service tier)
- `routes/` - Express router wiring (Web tier)

`middleware/auth.js` - JWT middleware. Attach to any route that requires a logged-in user via `router.method('/path', auth, controller)`. After verification it sets `req.user = { id, role }`.

## Payment Flow

Razorpay payment is a 3-step sequence:

1. `POST /api/payments/create` - creates a Razorpay order, stores `razorpayOrderId` on our Order document
2. iOS Razorpay SDK shows payment UI using that order ID
3. `POST /api/payments/verify` - verifies HMAC-SHA256 signature of `razorpayOrderId|razorpayPaymentId`, marks order as `paid`, decrements product stock

`POST /api/payments/webhook` is a server-side backup - Razorpay calls it directly for `payment.captured` and `payment.failed` events. This route uses `express.raw()` (registered before `express.json()` in `app.js`) because webhook signature verification requires the raw request body as a Buffer.

Razorpay amounts are always in **paise** (multiply INR by 100).

## Order Status Flow

```
pending → paid → shipped → delivered
                         → refunded
       → cancelled (payment failed)
```

Only sellers can update status to `shipped`/`delivered`. Only sellers can initiate refunds (order must be `paid`).

## Testing

`tests/setup.js` connects to the real Atlas database before all tests and wipes all collections before and after. Razorpay is mocked with `jest.mock('razorpay')` in `payments.test.js` so no real API calls are made. Tests run sequentially (`--runInBand`) because they share the same database.

## Local iOS Development

Run `npm run dev` and use `http://<mac-local-ip>:3000/api` as the base URL in the iOS app. Find your local IP with `ipconfig getifaddr en0`. iPhone and Mac must be on the same WiFi.
