const Order = require('../models/Order');
const Product = require('../models/Product');

exports.createOrder = async (req, res) => {
  const { productId, quantity } = req.body;

  const product = await Product.findById(productId);
  if (!product) return res.status(404).json({ message: 'Product not found' });
  if (product.stock < quantity) return res.status(400).json({ message: 'Insufficient stock' });

  const totalAmount = product.price * quantity;

  const order = await Order.create({
    buyer: req.user.id,
    product: product._id,
    seller: product.seller,
    quantity,
    totalAmount,
  });

  res.status(201).json(order);
};

exports.getMyOrders = async (req, res) => {
  const orders = await Order.find({ buyer: req.user.id }).populate('product', 'name price');
  res.json(orders);
};

exports.getSellerOrders = async (req, res) => {
  const orders = await Order.find({ seller: req.user.id }).populate('product', 'name price').populate('buyer', 'name email');
  res.json(orders);
};

exports.updateOrderStatus = async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ message: 'Order not found' });

  if (order.seller.toString() !== req.user.id) {
    return res.status(403).json({ message: 'Not authorized' });
  }

  const allowed = ['shipped', 'delivered'];
  if (!allowed.includes(req.body.status)) {
    return res.status(400).json({ message: 'Invalid status update' });
  }

  order.status = req.body.status;
  await order.save();
  res.json(order);
};
