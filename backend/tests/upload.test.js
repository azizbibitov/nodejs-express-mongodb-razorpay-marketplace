require('./setup');
const request = require('supertest');

jest.mock('../src/services/storage/CloudinaryStorage', () => ({
  upload: jest.fn().mockResolvedValue({
    url: 'https://res.cloudinary.com/test/image/upload/test.jpg',
    publicId: 'marketplace/products/test',
  }),
  delete: jest.fn().mockResolvedValue(),
}));

const app = require('../src/app');

describe('Upload', () => {
  let sellerToken;

  beforeAll(async () => {
    const seller = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Seller', email: 'seller@test.com', password: '123456', role: 'seller' });
    sellerToken = seller.body.token;
  });

  test('seller can upload an image', async () => {
    const res = await request(app)
      .post('/api/upload/image')
      .set('Authorization', `Bearer ${sellerToken}`)
      .attach('image', Buffer.from('fake-image-data'), { filename: 'test.jpg', contentType: 'image/jpeg' });
    expect(res.status).toBe(200);
    expect(res.body.url).toBe('https://res.cloudinary.com/test/image/upload/test.jpg');
    expect(res.body.publicId).toBe('marketplace/products/test');
  });

  test('rejects upload without auth', async () => {
    const res = await request(app)
      .post('/api/upload/image')
      .attach('image', Buffer.from('fake-image-data'), { filename: 'test.jpg', contentType: 'image/jpeg' });
    expect(res.status).toBe(401);
  });

  test('rejects non-image files', async () => {
    const res = await request(app)
      .post('/api/upload/image')
      .set('Authorization', `Bearer ${sellerToken}`)
      .attach('image', Buffer.from('not an image'), { filename: 'file.pdf', contentType: 'application/pdf' });
    expect(res.status).toBe(400);
  });
});
