const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);

async function getNearbyCustomerTokens(lat, lng, radiusKm = 25) {
  const { data, error } = await supabase.rpc('get_nearby_customers', { lat, lng, radius_km: radiusKm });
  if (error) throw error;
  return data?.map(r => r.fcm_token).filter(Boolean) || [];
}
async function getProduct(productId) {
  const { data } = await supabase.from('products').select('*, users(name, fcm_token)').eq('id', productId).single();
  return data;
}
async function getOrderWithUsers(orderId) {
  const { data } = await supabase.from('orders')
    .select('*, customer:customer_id(name, fcm_token), farmer:farmer_id(name, fcm_token)')
    .eq('id', orderId).single();
  return data;
}
async function updateOrderPayment(orderId, paymentId) {
  await supabase.from('orders').update({ payment_status: 'paid', payment_id: paymentId, status: 'confirmed', confirmed_at: new Date().toISOString() }).eq('id', orderId);
}
async function creditFarmerWallet(farmerId, amount, orderId) {
  const net = amount * 0.95;
  await supabase.from('farmer_wallets').upsert({ farmer_id: farmerId }).select();
  await supabase.rpc('credit_wallet', { p_farmer_id: farmerId, p_amount: net }).catch(() => {});
  await supabase.from('wallet_transactions').insert({ farmer_id: farmerId, order_id: orderId, type: 'credit', amount: net, description: `Order — ₹${amount} (5% fee deducted)` });
}
module.exports = { getNearbyCustomerTokens, getProduct, getOrderWithUsers, updateOrderPayment, creditFarmerWallet };
