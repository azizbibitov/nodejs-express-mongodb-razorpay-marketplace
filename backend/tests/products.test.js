require('./setup');
const request = require('supertest');

jest.mock('../src/services/storage/CloudinaryStorage', () => ({
  upload: jest.fn().mockResolvedValue({ url: 'https://test.com/img.jpg', publicId: 'test/img' }),
  delete: jest.fn().mockResolvedValue(),
}));

const app = require('../src/app');

describe('Products', () => {
  let sellerToken;
  let buyerToken;
  let productId;

  const product = {
    name: 'Test Shoes',
    description: 'Nice shoes',
    price: 49.99,
    stock: 10,
    category: 'footwear',
  };

  beforeAll(async () => {
    const seller = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Seller', email: 'seller@test.com', password: '123456', role: 'seller' });
    sellerToken = seller.body.token;

    const buyer = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Buyer', email: 'buyer@test.com', password: '123456', role: 'buyer' });
    buyerToken = buyer.body.token;
  });

  test('seller can create a product', async () => {
    const res = await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${sellerToken}`)
      .send(product);
    expect(res.status).toBe(201);
    expect(res.body.name).toBe(product.name);
    productId = res.body._id;
  });

  test('buyer cannot create a product', async () => {
    const res = await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send(product);
    expect(res.status).toBe(403);
  });

  test('anyone can list products', async () => {
    const res = await request(app).get('/api/products');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  test('anyone can get a single product', async () => {
    const res = await request(app).get(`/api/products/${productId}`);
    expect(res.status).toBe(200);
    expect(res.body._id).toBe(productId);
  });

  test('seller can update their product', async () => {
    const res = await request(app)
      .put(`/api/products/${productId}`)
      .set('Authorization', `Bearer ${sellerToken}`)
      .send({ price: 39.99 });
    expect(res.status).toBe(200);
    expect(res.body.price).toBe(39.99);
  });

  test('buyer cannot update someone elses product', async () => {
    const res = await request(app)
      .put(`/api/products/${productId}`)
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({ price: 1 });
    expect(res.status).toBe(403);
  });

  test('seller can delete their product', async () => {
    const res = await request(app)
      .delete(`/api/products/${productId}`)
      .set('Authorization', `Bearer ${sellerToken}`);
    expect(res.status).toBe(200);
  });
});
