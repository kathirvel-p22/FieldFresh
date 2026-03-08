const router = require('express').Router();
const { createClient } = require('@supabase/supabase-js');
const { sendHarvestBlast } = require('../services/firebase');
const { getNearbyCustomerTokens } = require('../services/supabase');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);

// POST /api/products/expire — manually expire old products
router.post('/expire', async (req, res) => {
  const { error } = await supabase.rpc('expire_old_products');
  if (error) return res.status(500).json({ error: error.message });
  res.json({ success: true, message: 'Expired listings cleaned up' });
});

// GET /api/products/nearby?lat=&lng=&radius=
router.get('/nearby', async (req, res) => {
  const { lat, lng, radius = 25, category } = req.query;
  let query = supabase.from('products').select('*, users(name, profile_image, rating)')
    .eq('status', 'active').gt('valid_until', new Date().toISOString()).gt('quantity_left', 0)
    .order('created_at', { ascending: false });
  if (category && category !== 'all') query = query.eq('category', category);
  const { data, error } = await query;
  if (error) return res.status(500).json({ error: error.message });
  res.json({ products: data, count: data.length });
});

module.exports = router;
