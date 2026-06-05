const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createRazorpayOrder, verifyPayment, handleWebhook, refundPayment } = require('../controllers/paymentController');

router.post('/create', auth, createRazorpayOrder);
router.post('/verify', auth, verifyPayment);
router.post('/webhook', handleWebhook);
router.post('/refund/:orderId', auth, refundPayment);

module.exports = router;
