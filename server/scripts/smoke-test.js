import { io } from 'socket.io-client';

const apiBaseUrl = process.env.SMOKE_API_BASE_URL || 'http://localhost:8081/api';
const socketOrigin = process.env.SMOKE_SOCKET_ORIGIN || new URL(apiBaseUrl).origin;
const adminEmail = process.env.SMOKE_ADMIN_EMAIL || 'admin@vyparhub.com';
const adminPassword = process.env.SMOKE_ADMIN_PASSWORD || 'Admin@123';
const customerPhone = process.env.SMOKE_CUSTOMER_PHONE || `777888${String(Date.now()).slice(-4)}`;
const customerPassword = process.env.SMOKE_CUSTOMER_PASSWORD || 'Demo@123';

async function api(path, { token, ...options } = {}) {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    ...options,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(`${options.method || 'GET'} ${path} failed ${response.status}: ${JSON.stringify(body)}`);
  }
  return body.data;
}

function waitForSocketEvent(socket, event, timeoutMs = 6000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${event}`)), timeoutMs);
    socket.once(event, (payload) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });
}

async function connectCustomerSocket(accessToken) {
  const socket = io(`${socketOrigin}/customer`, {
    auth: { token: accessToken },
    transports: ['websocket', 'polling'],
    reconnection: false,
  });
  await new Promise((resolve, reject) => {
    socket.once('connect', resolve);
    socket.once('connect_error', reject);
  });
  return socket;
}

async function main() {
  console.log(`Smoke target: ${apiBaseUrl}`);

  const adminSession = await api('/admin/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: adminEmail, password: adminPassword }),
  });
  console.log(`Admin login OK: ${adminSession.admin.email}`);

  const suffix = String(Date.now());
  const category = await api('/admin/categories', {
    token: adminSession.accessToken,
    method: 'POST',
    body: JSON.stringify({
      slug: `smoke-${suffix}`,
      nameEn: `Smoke Category ${suffix}`,
      imageUrl: 'products/parle-g.jpg',
      tint: '#FFE9D6',
      isActive: true,
    }),
  });

  const product = await api('/admin/products', {
    token: adminSession.accessToken,
    method: 'POST',
    body: JSON.stringify({
      sku: `smoke-product-${suffix}`,
      categoryId: category.id,
      nameEn: `Smoke Product ${suffix}`,
      brand: 'Smoke Brand',
      imageUrl: 'products/parle-g.jpg',
      mrp: 120,
      buyPrice: 90,
      stock: 25,
      isActive: true,
    }),
  });

  const variantA = await api(`/admin/products/${product.id}/variants`, {
    token: adminSession.accessToken,
    method: 'POST',
    body: JSON.stringify({
      variantName: '750ml',
      sku: `smoke-${suffix}-750ml`,
      mrp: 120,
      sellingPrice: 90,
      stockQuantity: 25,
      unit: 'ml',
      isDefault: true,
      status: 'active',
    }),
  });
  await api(`/admin/products/${product.id}/variants`, {
    token: adminSession.accessToken,
    method: 'POST',
    body: JSON.stringify({
      variantName: '1.25L',
      sku: `smoke-${suffix}-1250ml`,
      mrp: 180,
      sellingPrice: 140,
      stockQuantity: 18,
      unit: 'l',
      isDefault: false,
      status: 'active',
    }),
  });
  console.log(`Product + variants OK: ${product.id}`);

  const coupon = await api('/admin/offers', {
    token: adminSession.accessToken,
    method: 'POST',
    body: JSON.stringify({
      title: `Smoke Coupon ${suffix}`,
      subtitle: 'Smoke test coupon',
      couponCode: `SMOKE${suffix.slice(-5)}`,
      discountPercent: 10,
      appliesTo: 'all',
      isActive: true,
    }),
  });
  console.log(`Coupon OK: ${coupon.id}`);

  let customerSession;
  try {
    customerSession = await api('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        name: 'Smoke Customer',
        shopName: 'Smoke Store',
        phone: customerPhone,
        password: customerPassword,
        address: 'Smoke Market',
        area: 'Delhi',
        pincode: '110001',
      }),
    });
  } catch {
    customerSession = await api('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ phone: customerPhone, password: customerPassword }),
    });
  }

  const socket = await connectCustomerSocket(customerSession.accessToken);
  const eventPromise = waitForSocketEvent(socket, 'product.stock_changed');

  await api(`/admin/products/${product.id}/variants/${variantA.id}`, {
    token: adminSession.accessToken,
    method: 'PUT',
    body: JSON.stringify({
      variantName: '750ml',
      sku: variantA.sku,
      mrp: 120,
      sellingPrice: 90,
      stockQuantity: 12,
      unit: 'ml',
      isDefault: true,
      status: 'active',
    }),
  });

  const event = await eventPromise;
  socket.close();
  if (event.productId !== product.id || event.variantId !== variantA.id) {
    throw new Error(`Unexpected socket payload: ${JSON.stringify(event)}`);
  }

  console.log('Socket event OK: product.stock_changed');
  console.log('Smoke test passed.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
