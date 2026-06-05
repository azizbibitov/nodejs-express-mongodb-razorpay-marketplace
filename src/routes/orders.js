const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createOrder, getMyOrders, getSellerOrders, updateOrderStatus } = require('../controllers/orderController');

router.post('/', auth, createOrder);
router.get('/my', auth, getMyOrders);
router.get('/seller', auth, getSellerOrders);
router.patch('/:id/status', auth, updateOrderStatus);

module.exports = router;
