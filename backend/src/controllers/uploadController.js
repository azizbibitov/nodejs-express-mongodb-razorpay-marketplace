const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

exports.uploadImage = (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No file provided' });

  const stream = cloudinary.uploader.upload_stream(
    { folder: 'marketplace/products' },
    (error, result) => {
      if (error) return res.status(500).json({ message: error.message });
      res.json({ url: result.secure_url });
    }
  );

  stream.end(req.file.buffer);
};
