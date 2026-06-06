const Product = require('../models/Product');
const storage = require('../services/storage/CloudinaryStorage');

exports.createProduct = async (req, res) => {
  if (req.user.role !== 'seller') {
    return res.status(403).json({ message: 'Only sellers can create products' });
  }
  const { name, description, price, stock, category, images } = req.body;
  const product = await Product.create({
    name, description, price, stock, category,
    images: images || [],
    seller: req.user.id,
  });
  res.status(201).json(product);
};

exports.getProducts = async (req, res) => {
  const products = await Product.find().populate('seller', 'name email');
  res.json(products);
};

exports.getProduct = async (req, res) => {
  const product = await Product.findById(req.params.id).populate('seller', 'name email');
  if (!product) return res.status(404).json({ message: 'Product not found' });
  res.json(product);
};

exports.updateProduct = async (req, res) => {
  const product = await Product.findById(req.params.id);
  if (!product) return res.status(404).json({ message: 'Product not found' });
  if (product.seller.toString() !== req.user.id) {
    return res.status(403).json({ message: 'Not your product' });
  }

  // Delete images removed from the product
  if (req.body.images) {
    const newPublicIds = new Set(req.body.images.map((img) => img.publicId));
    const removed = product.images.filter((img) => !newPublicIds.has(img.publicId));
    await Promise.all(removed.map((img) => storage.delete(img.publicId)));
  }

  Object.assign(product, req.body);
  await product.save();
  res.json(product);
};

exports.deleteProduct = async (req, res) => {
  const product = await Product.findById(req.params.id);
  if (!product) return res.status(404).json({ message: 'Product not found' });
  if (product.seller.toString() !== req.user.id) {
    return res.status(403).json({ message: 'Not your product' });
  }

  // Delete all images from storage
  await Promise.all(product.images.map((img) => storage.delete(img.publicId)));

  await product.deleteOne();
  res.json({ message: 'Product deleted' });
};
