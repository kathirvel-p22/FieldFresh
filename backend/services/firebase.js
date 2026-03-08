const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  })});
}
const messaging = admin.messaging();

async function sendHarvestBlast({ tokens, productName, farmerName, price, unit, productId, imageUrl }) {
  if (!tokens || tokens.length === 0) return { sent: 0 };
  const msg = {
    notification: { title: `🌾 Fresh ${productName} just harvested!`, body: `${farmerName} — ₹${price}/${unit} | Limited stock!` },
    data: { product_id: productId, type: 'harvest_blast', click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    android: { priority: 'high', notification: { channelId: 'fieldfresh_channel', color: '#27AE60', sound: 'default' } },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  };
  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) chunks.push(tokens.slice(i, i + 500));
  let totalSent = 0;
  for (const chunk of chunks) {
    const res = await messaging.sendEachForMulticast({ ...msg, tokens: chunk });
    totalSent += res.successCount;
  }
  return { sent: totalSent, total: tokens.length };
}

async function sendOrderNotification({ token, title, body, orderId, type }) {
  if (!token) return;
  await messaging.send({
    token, notification: { title, body },
    data: { order_id: orderId, type, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    android: { priority: 'high', notification: { channelId: 'fieldfresh_channel', color: '#1B6CA8' } },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  });
}
module.exports = { sendHarvestBlast, sendOrderNotification };
