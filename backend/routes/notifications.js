const router = require('express').Router();
const { sendHarvestBlast, sendOrderNotification } = require('../services/firebase');
const { getNearbyCustomerTokens, getProduct } = require('../services/supabase');

// POST /api/notifications/harvest-blast
// Called when farmer posts a product — blast to all nearby customers
router.post('/harvest-blast', async (req, res) => {
  try {
    const { productId, farmerId } = req.body;
    if (!productId) return res.status(400).json({ error: 'productId required' });

    const product = await getProduct(productId);
    if (!product) return res.status(404).json({ error: 'Product not found' });

    // Get all customer FCM tokens within radius
    const tokens = await getNearbyCustomerTokens(product.latitude || 0, product.longitude || 0, 25);
    if (tokens.length === 0) return res.json({ message: 'No nearby customers', sent: 0 });

    const result = await sendHarvestBlast({
      tokens,
      productName: product.name,
      farmerName: product.users?.name || 'Local Farmer',
      price: product.price_per_unit,
      unit: product.unit,
      productId: product.id,
      imageUrl: product.image_urls?.[0],
    });

    console.log(`🌾 Harvest Blast sent for "${product.name}" → ${result.sent}/${tokens.length} customers`);
    res.json({ success: true, ...result });
  } catch (err) {
    console.error('Harvest blast error:', err);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/notifications/order-update
router.post('/order-update', async (req, res) => {
  try {
    const { token, title, body, orderId, type } = req.body;
    await sendOrderNotification({ token, title, body, orderId, type });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
