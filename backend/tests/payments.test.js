require('./setup');
const request = require('supertest');
const crypto = require('crypto');

// Mock Razorpay so tests don't make real API calls
jest.mock('razorpay', () => {
  return jest.fn().mockImplementation(() => ({
    orders: {
      create: jest.fn().mockResolvedValue({
        id: 'order_mock123',
        amount: 10000,
        currency: 'INR',
      }),
    },
    payments: {
      refund: jest.fn().mockResolvedValue({ id: 'refund_mock123' }),
    },
  }));
});

const app = require('../src/app');

describe('Payments', () => {
  let buyerToken;
  let sellerToken;
  let orderId;

  beforeAll(async () => {
    const seller = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Seller', email: 'seller@test.com', password: '123456', role: 'seller' });
    sellerToken = seller.body.token;

    const buyer = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Buyer', email: 'buyer@test.com', password: '123456', role: 'buyer' });
    buyerToken = buyer.body.token;

    const product = await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${sellerToken}`)
      .send({ name: 'Watch', description: 'Nice watch', price: 100, stock: 5, category: 'accessories' });

    const order = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({ productId: product.body._id, quantity: 1 });
    orderId = order.body._id;
  });

  test('buyer can create a Razorpay order', async () => {
    const res = await request(app)
      .post('/api/payments/create')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({ orderId });
    expect(res.status).toBe(200);
    expect(res.body.razorpayOrderId).toBe('order_mock123');
  });

  test('verifies payment with correct signature', async () => {
    const razorpayOrderId = 'order_mock123';
    const razorpayPaymentId = 'pay_mock456';
    const razorpaySignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    const res = await request(app)
      .post('/api/payments/verify')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({ orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature });
    expect(res.status).toBe(200);
    expect(res.body.order.status).toBe('paid');
  });

  test('rejects payment with wrong signature', async () => {
    const res = await request(app)
      .post('/api/payments/verify')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({
        orderId,
        razorpayOrderId: 'order_mock123',
        razorpayPaymentId: 'pay_mock456',
        razorpaySignature: 'invalidsignature',
      });
    expect(res.status).toBe(400);
  });

  test('seller can refund a paid order', async () => {
    const res = await request(app)
      .post(`/api/payments/refund/${orderId}`)
      .set('Authorization', `Bearer ${sellerToken}`);
    expect(res.status).toBe(200);
    expect(res.body.order.status).toBe('refunded');
  });

  test('webhook rejects invalid signature', async () => {
    const res = await request(app)
      .post('/api/payments/webhook')
      .set('Content-Type', 'application/json')
      .set('x-razorpay-signature', 'invalidsig')
      .send(Buffer.from(JSON.stringify({ event: 'payment.captured' })));
    expect(res.status).toBe(400);
  });
});
