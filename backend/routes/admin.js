const router = require('express').Router();
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);

router.get('/stats', async (req, res) => {
  try {
    const [farmers, customers, orders, products] = await Promise.all([
      supabase.from('users').select('id', { count: 'exact' }).eq('role', 'farmer'),
      supabase.from('users').select('id', { count: 'exact' }).eq('role', 'customer'),
      supabase.from('orders').select('total_amount, status'),
      supabase.from('products').select('id', { count: 'exact' }).eq('status', 'active'),
    ]);
    const totalRevenue = orders.data?.filter(o => o.status === 'delivered')
      .reduce((s, o) => s + Number(o.total_amount), 0) || 0;
    res.json({
      totalFarmers: farmers.count || 0,
      totalCustomers: customers.count || 0,
      totalOrders: orders.data?.length || 0,
      activeProducts: products.count || 0,
      totalRevenue,
      platformRevenue: totalRevenue * 0.05,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/pending-kyc', async (req, res) => {
  const { data } = await supabase.from('users').select('*').eq('is_kyc_done', false).eq('role', 'farmer');
  res.json({ farmers: data });
});

router.post('/approve-farmer/:id', async (req, res) => {
  await supabase.from('users').update({ is_verified: true, is_kyc_done: true }).eq('id', req.params.id);
  res.json({ success: true });
});

module.exports = router;
