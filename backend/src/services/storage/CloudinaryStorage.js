const cloudinary = require('cloudinary').v2;
const ImageStorage = require('./ImageStorage');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

class CloudinaryStorage extends ImageStorage {
  async upload(buffer, filename) {
    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        { folder: 'marketplace/products' },
        (error, result) => {
          if (error) return reject(error);
          resolve({ url: result.secure_url, publicId: result.public_id });
        }
      );
      stream.end(buffer);
    });
  }

  async delete(publicId) {
    await cloudinary.uploader.destroy(publicId);
  }
}

module.exports = new CloudinaryStorage();
