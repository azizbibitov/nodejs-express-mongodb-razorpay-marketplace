require('./setup');
const request = require('supertest');
const app = require('../src/app');

describe('Orders', () => {
  let sellerToken;
  let buyerToken;
  let productId;
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
      .send({ name: 'Shoes', description: 'Nice', price: 50, stock: 10, category: 'footwear' });
    productId = product.body._id;
  });

  test('buyer can place an order', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({ productId, quantity: 2 });
    expect(res.status).toBe(201);
    expect(res.body.totalAmount).toBe(100);
    expect(res.body.status).toBe('pending');
    orderId = res.body._id;
  });

  test('buyer can view their orders', async () => {
    const res = await request(app)
      .get('/api/orders/my')
      .set('Authorization', `Bearer ${buyerToken}`);
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
  });

  test('seller can view their orders', async () => {
    const res = await request(app)
      .get('/api/orders/seller')
      .set('Authorization', `Bearer ${sellerToken}`);
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
  });

  test('seller can mark order as shipped', async () => {
    const res = await request(app)
      .patch(`/api/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${sellerToken}`)
      .send({ status: 'shipped' });
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('shipped');
  });

  test('buyer cannot update order status', async () => {
    const res = await request(app)
      .patch(`/api/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({ status: 'delivered' });
    expect(res.status).toBe(403);
  });

  test('rejects order if stock is insufficient', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({ productId, quantity: 999 });
    expect(res.status).toBe(400);
  });
});
