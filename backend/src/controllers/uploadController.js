const storage = require('../services/storage/CloudinaryStorage');

exports.uploadImage = async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No file provided' });
  try {
    const result = await storage.upload(req.file.buffer, req.file.originalname);
    res.json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
