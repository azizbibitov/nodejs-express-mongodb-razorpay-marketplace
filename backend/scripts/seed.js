/**
 * Seed script - populates the marketplace database with presentation-ready
 * sample data: a catalog of products with real Cloudinary images and orders
 * spanning every status, spread across several months.
 *
 * Run from backend/:  node scripts/seed.js
 *
 * - Keeps the existing seller + buyer accounts, resetting their passwords to
 *   known demo values so login is guaranteed.
 * - Wipes all products and orders, then inserts fresh sample data.
 *
 * Demo credentials after running:
 *   seller (macOS admin): admin@marketplace.com / password123
 *   buyer  (iOS app):     Aziz@gmail.com        / password123
 */
require('dotenv/config');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

const SELLER_EMAIL = 'admin@marketplace.com';
const BUYER_EMAIL = 'Aziz@gmail.com';
const DEMO_PASSWORD = 'password123';

const CLOUD = 'duwrigauv';
// Real images already in this account's Cloudinary library.
const img = (publicId, version, ext = 'jpg') => ({
  publicId,
  url: `https://res.cloudinary.com/${CLOUD}/image/upload/v${version}/${publicId}.${ext}`,
});

const IMAGES = {
  leatherBag: img('samples/ecommerce/leather-bag-gray', 1780702689),
  accessoriesBag: img('samples/ecommerce/accessories-bag', 1780702689),
  shoesWhite: img('samples/ecommerce/shoes', 1780702686, 'png'),
  watch: img('samples/ecommerce/analog-classic', 1780702683),
  carInterior: img('samples/ecommerce/car-interior-design', 1780702689),
  bike: img('samples/bike', 1780702686),
  shoe: img('samples/shoe', 1780702695),
  chair: img('samples/chair', 1780702700, 'png'),
  chairTable: img('samples/chair-and-coffee-table', 1780702699),
  coffee: img('samples/coffee', 1780702700),
  cup: img('samples/cup-on-a-table', 1780702701),
  dessert: img('samples/food/dessert', 1780702683),
  dessertPlate: img('samples/dessert-on-a-plate', 1780702701),
  spices: img('samples/food/spices', 1780702690),
  fish: img('samples/food/fish-vegetables', 1780702685),
  mussels: img('samples/food/pot-mussels', 1780702685),
  balloons: img('samples/balloons', 1780702696),
};

// Helper to build a fixed date (avoids Date.now drift in the seed output).
const at = (y, m, d, h = 12, min = 0) => new Date(Date.UTC(y, m - 1, d, h, min));

const PRODUCTS = [
  {
    name: 'Gray Leather Tote Bag',
    description:
      'Handcrafted full-grain leather tote with a soft suede lining and gold-tone hardware. Roomy enough for a laptop and everyday essentials.',
    price: 189.0,
    stock: 12,
    category: 'Bags',
    images: [IMAGES.leatherBag, IMAGES.accessoriesBag],
  },
  {
    name: 'Canvas Weekender Bag',
    description:
      'Durable waxed-canvas weekender with leather trim and a detachable shoulder strap. Perfect carry-on for short trips.',
    price: 129.0,
    stock: 8,
    category: 'Bags',
    images: [IMAGES.accessoriesBag],
  },
  {
    name: 'Classic White Sneakers',
    description:
      'Minimalist low-top sneakers in premium white leather with a cushioned insole. Goes with everything.',
    price: 95.0,
    stock: 25,
    category: 'Footwear',
    images: [IMAGES.shoesWhite, IMAGES.shoe],
  },
  {
    name: 'Running Performance Shoe',
    description:
      'Lightweight breathable runner with responsive foam midsole and a grippy outsole for road and trail.',
    price: 119.0,
    stock: 0, // out of stock - shows the stock badge in the apps
    category: 'Footwear',
    images: [IMAGES.shoe],
  },
  {
    name: 'Analog Classic Watch',
    description:
      'Timeless stainless-steel watch with a genuine leather strap, sapphire crystal, and 5 ATM water resistance.',
    price: 245.0,
    stock: 15,
    category: 'Accessories',
    images: [IMAGES.watch],
  },
  {
    name: 'City Commuter Bicycle',
    description:
      'Single-speed steel-frame city bike with puncture-resistant tires and a comfortable upright geometry.',
    price: 540.0,
    stock: 5,
    category: 'Sports',
    images: [IMAGES.bike],
  },
  {
    name: 'Mid-Century Lounge Chair',
    description:
      'Sculpted walnut lounge chair with a molded shell and tapered legs. A statement piece for any room.',
    price: 420.0,
    stock: 6,
    category: 'Furniture',
    images: [IMAGES.chair, IMAGES.chairTable],
  },
  {
    name: 'Coffee Table & Chair Set',
    description:
      'Matching coffee table and accent chair in light oak. Clean Scandinavian lines for the modern living room.',
    price: 680.0,
    stock: 3,
    category: 'Furniture',
    images: [IMAGES.chairTable],
  },
  {
    name: 'Artisan Coffee Mug',
    description:
      'Hand-thrown stoneware mug with a reactive glaze. Holds 350ml and is dishwasher safe.',
    price: 24.0,
    stock: 60,
    category: 'Kitchen',
    images: [IMAGES.coffee, IMAGES.cup],
  },
  {
    name: 'Ceramic Espresso Cup',
    description:
      'Petite matte-finish espresso cup, fired at high temperature for a durable everyday piece.',
    price: 18.0,
    stock: 40,
    category: 'Kitchen',
    images: [IMAGES.cup],
  },
  {
    name: 'Gourmet Spice Collection',
    description:
      'Curated set of twelve single-origin spices in resealable tins. Freshly milled and ethically sourced.',
    price: 49.0,
    stock: 30,
    category: 'Food',
    images: [IMAGES.spices],
  },
  {
    name: 'Artisan Dessert Box',
    description:
      'A box of six handcrafted French-style desserts, made fresh and delivered chilled.',
    price: 38.0,
    stock: 20,
    category: 'Food',
    images: [IMAGES.dessert, IMAGES.dessertPlate],
  },
  {
    name: 'Fresh Catch Seafood Platter',
    description:
      'Chef-prepared fish and seasonal vegetables, vacuum-sealed and ready to heat. Serves two.',
    price: 64.0,
    stock: 10,
    category: 'Food',
    images: [IMAGES.fish, IMAGES.mussels],
  },
  {
    name: 'Celebration Balloon Bundle',
    description:
      'A bundle of 30 premium matte latex balloons in a curated color palette for parties and events.',
    price: 22.0,
    stock: 50,
    category: 'Party',
    images: [IMAGES.balloons],
  },
];

// Orders reference products by their index in PRODUCTS above.
// One entry per (status, month) combination to give a realistic history.
const payId = (n) => `pay_DEMO${String(n).padStart(8, '0')}`;
const rzpOrderId = (n) => `order_DEMO${String(n).padStart(7, '0')}`;

const ORDERS = [
  // --- Delivered (older history) ---
  { productIdx: 2, qty: 1, status: 'delivered', date: at(2026, 2, 14, 10, 5), pay: payId(1), rzp: rzpOrderId(1) },
  { productIdx: 8, qty: 2, status: 'delivered', date: at(2026, 3, 3, 16, 40), pay: payId(2), rzp: rzpOrderId(2) },
  { productIdx: 4, qty: 1, status: 'delivered', date: at(2026, 3, 22, 9, 15), pay: payId(3), rzp: rzpOrderId(3) },
  // --- Refunded ---
  { productIdx: 5, qty: 1, status: 'refunded', date: at(2026, 3, 28, 13, 0), pay: payId(4), rzp: rzpOrderId(4) },
  { productIdx: 10, qty: 1, status: 'refunded', date: at(2026, 4, 11, 11, 30), pay: payId(5), rzp: rzpOrderId(5) },
  // --- Shipped (in transit) ---
  { productIdx: 0, qty: 1, status: 'shipped', date: at(2026, 5, 2, 14, 20), pay: payId(6), rzp: rzpOrderId(6) },
  { productIdx: 11, qty: 1, status: 'shipped', date: at(2026, 5, 18, 18, 45), pay: payId(7), rzp: rzpOrderId(7) },
  // --- Paid (awaiting shipment) ---
  { productIdx: 6, qty: 1, status: 'paid', date: at(2026, 5, 26, 12, 10), pay: payId(8), rzp: rzpOrderId(8) },
  { productIdx: 9, qty: 3, status: 'paid', date: at(2026, 6, 1, 8, 50), pay: payId(9), rzp: rzpOrderId(9) },
  // --- Cancelled (payment failed) ---
  { productIdx: 7, qty: 1, status: 'cancelled', date: at(2026, 5, 9, 20, 0), pay: null, rzp: rzpOrderId(10) },
  // --- Pending (just placed, not yet paid) ---
  { productIdx: 1, qty: 1, status: 'pending', date: at(2026, 6, 5, 17, 35), pay: null, rzp: null },
  { productIdx: 12, qty: 2, status: 'pending', date: at(2026, 6, 6, 9, 0), pay: null, rzp: null },
];

async function main() {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;
  console.log('Connected to', db.databaseName);

  const users = db.collection('users');
  const products = db.collection('products');
  const orders = db.collection('orders');

  // 1. Resolve / reset the two demo accounts.
  const hashed = await bcrypt.hash(DEMO_PASSWORD, 10);
  const seller = await users.findOne({ email: SELLER_EMAIL });
  const buyer = await users.findOne({ email: BUYER_EMAIL });
  if (!seller) throw new Error(`Seller ${SELLER_EMAIL} not found`);
  if (!buyer) throw new Error(`Buyer ${BUYER_EMAIL} not found`);

  await users.updateOne({ _id: seller._id }, { $set: { password: hashed, role: 'seller' } });
  await users.updateOne({ _id: buyer._id }, { $set: { password: hashed, role: 'buyer' } });
  console.log('Reset passwords for seller + buyer to:', DEMO_PASSWORD);

  // 2. Wipe products + orders.
  const delP = await products.deleteMany({});
  const delO = await orders.deleteMany({});
  console.log(`Wiped ${delP.deletedCount} products, ${delO.deletedCount} orders`);

  // 3. Insert products (raw driver so we control timestamps).
  const productDocs = PRODUCTS.map((p, i) => ({
    _id: new mongoose.Types.ObjectId(),
    name: p.name,
    description: p.description,
    price: p.price,
    stock: p.stock,
    category: p.category,
    seller: seller._id,
    images: p.images,
    createdAt: at(2026, 1, 15 + i, 9),
    updatedAt: at(2026, 1, 15 + i, 9),
    __v: 0,
  }));
  await products.insertMany(productDocs);
  console.log(`Inserted ${productDocs.length} products`);

  // 4. Insert orders.
  const orderDocs = ORDERS.map((o) => {
    const product = productDocs[o.productIdx];
    const doc = {
      _id: new mongoose.Types.ObjectId(),
      buyer: buyer._id,
      product: product._id,
      seller: seller._id,
      quantity: o.qty,
      totalAmount: Number((product.price * o.qty).toFixed(2)),
      status: o.status,
      createdAt: o.date,
      updatedAt: o.date,
      __v: 0,
    };
    if (o.rzp) doc.razorpayOrderId = o.rzp;
    if (o.pay) doc.razorpayPaymentId = o.pay;
    return doc;
  });
  await orders.insertMany(orderDocs);
  console.log(`Inserted ${orderDocs.length} orders`);

  // Summary by status.
  const byStatus = orderDocs.reduce((acc, o) => {
    acc[o.status] = (acc[o.status] || 0) + 1;
    return acc;
  }, {});
  console.log('Orders by status:', byStatus);

  await mongoose.disconnect();
  console.log('Done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
