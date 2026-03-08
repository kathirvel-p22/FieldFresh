const router = require('express').Router();
const Razorpay = require('razorpay');
const crypto = require('crypto');
const { updateOrderPayment, creditFarmerWallet, getOrderWithUsers } = require('../services/supabase');
const { sendOrderNotification } = require('../services/firebase');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// POST /api/payments/create-order
router.post('/create-order', async (req, res) => {
  try {
    const { amount, currency = 'INR', receipt } = req.body;
    const order = await razorpay.orders.create({ amount: Math.round(amount * 100), currency, receipt });
    res.json({ orderId: order.id, amount: order.amount, currency: order.currency });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/payments/verify
router.post('/verify', async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, internal_order_id } = req.body;
    // Verify signature
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body).digest('hex');

    if (expectedSignature !== razorpay_signature) {
      return res.status(400).json({ error: 'Invalid payment signature' });
    }

    // Update DB
    await updateOrderPayment(internal_order_id, razorpay_payment_id);

    // Get order to credit farmer + send notifications
    const order = await getOrderWithUsers(internal_order_id);
    if (order) {
      await creditFarmerWallet(order.farmer_id, order.total_amount, internal_order_id);
      // Notify farmer
      if (order.farmer?.fcm_token) {
        await sendOrderNotification({
          token: order.farmer.fcm_token,
          title: '🎉 New Order Received!',
          body: `${order.product_name} — ₹${order.total_amount}`,
          orderId: internal_order_id, type: 'new_order',
        });
      }
      // Notify customer
      if (order.customer?.fcm_token) {
        await sendOrderNotification({
          token: order.customer.fcm_token,
          title: '✅ Order Confirmed!',
          body: `Your order for ${order.product_name} is confirmed. Track it now!`,
          orderId: internal_order_id, type: 'order_confirmed',
        });
      }
    }
    res.json({ success: true, payment_id: razorpay_payment_id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
