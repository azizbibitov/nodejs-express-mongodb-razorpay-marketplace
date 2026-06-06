/**
 * ImageStorage defines the contract for any image storage provider.
 * Swap Cloudinary for S3, GCS, etc. by implementing this class.
 *
 * upload(buffer, filename) -> Promise<{ url: string, publicId: string }>
 * delete(publicId)         -> Promise<void>
 */
class ImageStorage {
  async upload(buffer, filename) {
    throw new Error('upload() not implemented');
  }

  async delete(publicId) {
    throw new Error('delete() not implemented');
  }
}

module.exports = ImageStorage;
