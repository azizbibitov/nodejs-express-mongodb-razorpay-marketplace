const crypto = require('crypto');
const Razorpay = require('razorpay');
const Order = require('../models/Order');
const Product = require('../models/Product');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// Step 1: Buyer initiates payment - creates a Razorpay order for our order
exports.createRazorpayOrder = async (req, res) => {
  const order = await Order.findById(req.body.orderId);
  if (!order) return res.status(404).json({ message: 'Order not found' });
  if (order.buyer.toString() !== req.user.id) {
    return res.status(403).json({ message: 'Not your order' });
  }
  if (order.status !== 'pending') {
    return res.status(400).json({ message: 'Order is not in pending state' });
  }

  const razorpayOrder = await razorpay.orders.create({
    amount: Math.round(order.totalAmount * 100), // Razorpay uses paise (1 INR = 100 paise)
    currency: 'INR',
    receipt: order._id.toString(),
  });

  order.razorpayOrderId = razorpayOrder.id;
  await order.save();

  res.json({ razorpayOrderId: razorpayOrder.id, amount: razorpayOrder.amount, currency: razorpayOrder.currency });
};

// Step 2: After iOS Razorpay SDK collects payment, verify the signature
exports.verifyPayment = async (req, res) => {
  const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest('hex');

  if (expectedSignature !== razorpaySignature) {
    return res.status(400).json({ message: 'Invalid payment signature' });
  }

  const order = await Order.findById(orderId);
  if (!order) return res.status(404).json({ message: 'Order not found' });

  order.status = 'paid';
  order.razorpayPaymentId = razorpayPaymentId;
  await order.save();

  // Deduct stock
  await Product.findByIdAndUpdate(order.product, { $inc: { stock: -order.quantity } });

  res.json({ message: 'Payment verified', order });
};

// Step 3: Razorpay calls this automatically when payment events happen
exports.handleWebhook = async (req, res) => {
  const webhookSignature = req.headers['x-razorpay-signature'];
  const body = req.body; // raw Buffer because of express.raw()

  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(body)
    .digest('hex');

  if (expectedSignature !== webhookSignature) {
    return res.status(400).json({ message: 'Invalid webhook signature' });
  }

  const event = JSON.parse(body.toString());

  if (event.event === 'payment.captured') {
    const razorpayOrderId = event.payload.payment.entity.order_id;
    await Order.findOneAndUpdate({ razorpayOrderId }, { status: 'paid' });
  }

  if (event.event === 'payment.failed') {
    const razorpayOrderId = event.payload.payment.entity.order_id;
    await Order.findOneAndUpdate({ razorpayOrderId }, { status: 'cancelled' });
  }

  res.json({ received: true });
};

// Seller can refund a paid order
exports.refundPayment = async (req, res) => {
  const order = await Order.findById(req.params.orderId);
  if (!order) return res.status(404).json({ message: 'Order not found' });
  if (order.seller.toString() !== req.user.id) {
    return res.status(403).json({ message: 'Not authorized' });
  }
  if (order.status !== 'paid') {
    return res.status(400).json({ message: 'Only paid orders can be refunded' });
  }

  await razorpay.payments.refund(order.razorpayPaymentId, {
    amount: Math.round(order.totalAmount * 100),
  });

  order.status = 'refunded';
  await order.save();

  res.json({ message: 'Refund initiated', order });
};
