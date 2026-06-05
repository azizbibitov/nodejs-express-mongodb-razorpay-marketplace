require('./setup');
const request = require('supertest');
const path = require('path');
const fs = require('fs');

jest.mock('cloudinary', () => ({
  v2: {
    config: jest.fn(),
    uploader: {
      upload_stream: jest.fn((options, callback) => {
        callback(null, { secure_url: 'https://res.cloudinary.com/test/image/upload/test.jpg' });
        return { end: jest.fn() };
      }),
    },
  },
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
    const imgBuffer = Buffer.from('fake-image-data');
    const res = await request(app)
      .post('/api/upload/image')
      .set('Authorization', `Bearer ${sellerToken}`)
      .attach('image', imgBuffer, { filename: 'test.jpg', contentType: 'image/jpeg' });
    expect(res.status).toBe(200);
    expect(res.body.url).toBe('https://res.cloudinary.com/test/image/upload/test.jpg');
  });

  test('rejects upload without auth', async () => {
    const imgBuffer = Buffer.from('fake-image-data');
    const res = await request(app)
      .post('/api/upload/image')
      .attach('image', imgBuffer, { filename: 'test.jpg', contentType: 'image/jpeg' });
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
