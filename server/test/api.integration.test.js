import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import http from 'node:http';
import test, { after, before } from 'node:test';

import bcrypt from 'bcryptjs';
import { io as socketClient } from 'socket.io-client';
import request from 'supertest';

process.env.NODE_ENV = 'test';
process.env.JWT_ACCESS_SECRET ||= 'phase7-test-access-secret';
process.env.JWT_REFRESH_SECRET ||= 'phase7-test-refresh-secret';
process.env.ADMIN_JWT_ACCESS_SECRET ||= 'phase8-test-admin-access-secret';
process.env.ADMIN_JWT_REFRESH_SECRET ||= 'phase8-test-admin-refresh-secret';
process.env.OTP_PROVIDER = 'mock';
process.env.OTP_DEV_CODE = '1234';
process.env.RAZORPAY_WEBHOOK_SECRET = 'phase7-test-webhook-secret';
process.env.CORS_ORIGIN ||= 'http://localhost:8082';

const { app } = await import('../src/app.js');
const { pool } = await import('../src/config/db.js');
const { initRealtime } = await import('../src/services/realtimeService.js');

const agent = request(app);
const testPrefix = `phase7_${Date.now()}`;
let fixtureCounter = 0;

async function cleanup() {
  await pool.query(
    `
      delete from payments
      where order_id in (
        select o.id from orders o join users u on u.id = o.user_id where u.phone like '777000%'
      )
    `,
  );
  await pool.query(
    `
      delete from refund_requests
      where order_id in (
        select o.id from orders o join users u on u.id = o.user_id where u.phone like '777000%'
      )
    `,
  );
  await pool.query(
    `
      delete from refunds
      where order_id in (
        select o.id from orders o join users u on u.id = o.user_id where u.phone like '777000%'
      )
    `,
  );
  await pool.query(
    `
      delete from order_status_history
      where order_id in (
        select o.id from orders o join users u on u.id = o.user_id where u.phone like '777000%'
      )
    `,
  );
  await pool.query(
    `
      delete from order_items
      where order_id in (
        select o.id from orders o join users u on u.id = o.user_id where u.phone like '777000%'
      )
    `,
  );
  await pool.query(
    "delete from orders where user_id in (select id from users where phone like '777000%')",
  );
  await pool.query(
    "delete from cart_items where user_id in (select id from users where phone like '777000%')",
  );
  await pool.query(
    "delete from addresses where user_id in (select id from users where phone like '777000%')",
  );
  await pool.query("delete from users where phone like '777000%'");
  await pool.query("delete from offers where title like 'Phase 8 %'");
  await pool.query("delete from product_variants where product_id in (select id from products where sku like 'phase7-%')");
  await pool.query("delete from product_variants where product_id in (select id from products where sku like 'phase-import-%')");
  await pool.query("delete from products where sku like 'phase7-%'");
  await pool.query("delete from products where sku like 'phase-import-%'");
  await pool.query("delete from categories where slug like 'phase7-%'");
  await pool.query("delete from categories where slug like 'phase-import-%'");
  await pool.query("delete from otp_codes where phone like '777000%'");
  await pool.query("delete from admins where email like 'phase8-%@vyparhub.test'");
  await pool.query("delete from role_permissions where role_id in (select id from roles where name like 'Phase 8 %')");
  await pool.query("delete from roles where name like 'Phase 8 %'");
  await pool.query("delete from brands where name like 'Phase 8 %'");
  await pool.query("delete from brands where name like 'Phase Import %'");
  await pool.query("delete from loyalty_tiers where name like 'Phase 8 %'");
  await pool.query("delete from loyalty_rules where action like 'phase8_%'");
  await pool.query("delete from redeemable_rewards where title like 'Phase 8 %'");
  await pool.query("delete from delivery_zones where name like 'Phase 8 %'");
  await pool.query("delete from home_sections where title like 'Phase 8 %'");
}

async function createFixtureProduct() {
  fixtureCounter += 1;
  const fixtureKey = `${testPrefix}_${fixtureCounter}`;
  const category = await pool.query(
    `
      insert into categories(slug, name_en, image_url, tint)
      values($1, 'Phase 7 Test', 'products/parle-g.jpg', '#FFE9D6')
      returning id
    `,
    [`phase7-${fixtureKey}`],
  );
  const product = await pool.query(
    `
      insert into products(
        sku, category_id, brand, name_en, size, pack, image_url,
        mrp, buy_price, stock, regional, high_margin, trending_areas, is_active
      )
      values($1, $2, 'PhaseBrand', 'Phase 7 Product', '1 kg', '12', 'products/parle-g.jpg',
        120, 90, 50, false, true, '{}', true)
      returning id
    `,
    [`phase7-${fixtureKey}`, category.rows[0].id],
  );
  await pool.query(
    `
      insert into product_variants(product_id, size, pack, mrp, buy_price)
      values($1, '2 kg', '6', 220, 170)
    `,
    [product.rows[0].id],
  );
  return product.rows[0].id;
}

async function registerUser(phone, password = 'Demo@123') {
  const response = await agent.post('/api/auth/register').send({
    name: `Phase User ${phone.slice(-2)}`,
    shopName: 'Phase 7 Store',
    phone,
    password,
    address: 'Phase 7 Market',
    area: 'Delhi',
    pincode: '110001',
  });
  assert.equal(response.status, 201, response.text);
  return response.body.data;
}

async function createAdminSession({
  email = `phase8-super-${Date.now()}@vyparhub.test`,
  permissions = null,
} = {}) {
  const roleName = permissions ? `Phase 8 Limited ${Date.now()} ${Math.random()}` : 'Super Admin';
  let roleId;
  if (permissions) {
    const role = await pool.query(
      "insert into roles(name, description, status) values($1, 'Phase 8 test role', 'active') returning id",
      [roleName],
    );
    roleId = role.rows[0].id;
    for (const permission of permissions) {
      await pool.query(
        'insert into role_permissions(role_id,module,action,allowed) values($1,$2,$3,true)',
        [roleId, permission.module, permission.action],
      );
    }
  } else {
    const role = await pool.query("select id from roles where name='Super Admin'");
    roleId = role.rows[0].id;
  }

  const password = 'Admin@123';
  await pool.query(
    'insert into admins(name,email,password_hash,role_id,status) values($1,$2,$3,$4,$5)',
    ['Phase 8 Admin', email, await bcrypt.hash(password, 8), roleId, 'active'],
  );
  const response = await agent.post('/api/admin/auth/login').send({ email, password });
  assert.equal(response.status, 200, response.text);
  return response.body.data;
}

async function createAdminCategory(token, suffix = Date.now()) {
  const response = await agent
    .post('/api/admin/categories')
    .set('Authorization', `Bearer ${token}`)
    .send({
      slug: `phase7-${testPrefix}-${suffix}`,
      nameEn: `Phase 8 Category ${suffix}`,
      imageUrl: 'products/parle-g.jpg',
      tint: '#FFE9D6',
      isActive: true,
    });
  assert.equal(response.status, 201, response.text);
  return response.body.data;
}

async function createAdminProductWithVariant(token) {
  const category = await createAdminCategory(token, `product-${Date.now()}`);
  const productResponse = await agent
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${token}`)
    .send({
      sku: `phase7-admin-${Date.now()}`,
      categoryId: category.id,
      nameEn: 'Phase 8 Test Product',
      brand: 'Phase 8 Brand',
      imageUrl: 'products/parle-g.jpg',
      mrp: 100,
      buyPrice: 80,
      stock: 20,
      isActive: true,
    });
  assert.equal(productResponse.status, 201, productResponse.text);
  const product = productResponse.body.data;
  const variantResponse = await agent
    .post(`/api/admin/products/${product.id}/variants`)
    .set('Authorization', `Bearer ${token}`)
    .send({
      variantName: '750ml',
      sku: `phase8-variant-${Date.now()}`,
      mrp: 95,
      sellingPrice: 75,
      stockQuantity: 15,
      unit: 'ml',
      isDefault: true,
      status: 'active',
    });
  assert.equal(variantResponse.status, 201, variantResponse.text);
  return { category, product, variant: variantResponse.body.data };
}

async function createAddress(token) {
  const response = await agent
    .post('/api/addresses')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Phase Receiver',
      phone: '7770001000',
      line1: 'Phase 7 Test Address',
      area: 'Test Area',
      city: 'Delhi',
      state: 'Delhi',
      pincode: '110001',
      isDefault: true,
    });
  assert.equal(response.status, 201, response.text);
  return response.body.data.id;
}

async function dashboardOrderMetrics(token) {
  const response = await agent
    .get('/api/admin/dashboard')
    .set('Authorization', `Bearer ${token}`);
  assert.equal(response.status, 200, response.text);
  const orders = response.body.data.orders;
  return {
    grossSales: Number(orders.gross_sales ?? orders.revenue ?? 0),
    netSales: Number(orders.net_sales ?? 0),
    pendingRevenue: Number(orders.pending_revenue ?? 0),
    cancelledValue: Number(orders.cancelled_value ?? 0),
    refundedAmount: Number(orders.refunded_amount ?? 0),
    deliveredCount: Number(orders.delivered_count ?? 0),
    cancelledCount: Number(orders.cancelled_count ?? 0),
  };
}

before(async () => {
  await cleanup();
});

after(async () => {
  await cleanup();
  await pool.end();
});

test('OTP request and verify returns a customer session', async () => {
  const phone = '7770001001';
  const requestResponse = await agent.post('/api/auth/otp/send').send({ phone });
  assert.equal(requestResponse.status, 201, requestResponse.text);
  assert.equal(requestResponse.body.data.devCode, '123456');

  const verifyResponse = await agent.post('/api/auth/otp/verify').send({
    phone,
    code: '123456',
    name: 'OTP Phase User',
    shopName: 'OTP Phase Store',
    address: 'OTP Address',
    area: 'Delhi',
    pincode: '110001',
  });

  assert.equal(verifyResponse.status, 200, verifyResponse.text);
  assert.equal(verifyResponse.body.data.user.phone, phone);
  assert.equal(verifyResponse.body.data.user.role, 'customer');
  assert.ok(verifyResponse.body.data.accessToken);
});

test('cart add, remove, and get are persisted per user', async () => {
  const productId = await createFixtureProduct();
  const session = await registerUser('7770001002');
  const token = session.accessToken;

  const addResponse = await agent
    .post('/api/cart/add')
    .set('Authorization', `Bearer ${token}`)
    .send({ productId, variantKey: '2_kg', quantity: 2 });
  assert.equal(addResponse.status, 201, addResponse.text);
  assert.equal(addResponse.body.data.summary.count, 2);

  const getResponse = await agent.get('/api/cart').set('Authorization', `Bearer ${token}`);
  assert.equal(getResponse.status, 200, getResponse.text);
  assert.equal(getResponse.body.data.items[0].variantKey, '2_kg');

  const removeResponse = await agent
    .post('/api/cart/remove')
    .set('Authorization', `Bearer ${token}`)
    .send({ productId, variantKey: '2_kg', quantity: 1 });
  assert.equal(removeResponse.status, 200, removeResponse.text);
  assert.equal(removeResponse.body.data.summary.count, 1);
});

test('address CRUD is scoped to the authenticated user', async () => {
  const owner = await registerUser('7770001003');
  const stranger = await registerUser('7770001004');
  const addressId = await createAddress(owner.accessToken);

  const updateResponse = await agent
    .put(`/api/addresses/${addressId}`)
    .set('Authorization', `Bearer ${owner.accessToken}`)
    .send({ line1: 'Updated Phase 7 Address', isDefault: true });
  assert.equal(updateResponse.status, 200, updateResponse.text);
  assert.equal(updateResponse.body.data.line1, 'Updated Phase 7 Address');

  const strangerDelete = await agent
    .delete(`/api/addresses/${addressId}`)
    .set('Authorization', `Bearer ${stranger.accessToken}`);
  assert.equal(strangerDelete.status, 404);

  const ownerDelete = await agent
    .delete(`/api/addresses/${addressId}`)
    .set('Authorization', `Bearer ${owner.accessToken}`);
  assert.equal(ownerDelete.status, 200, ownerDelete.text);
});

test('order creation writes normalized order_items and blocks cross-user reads', async () => {
  const productId = await createFixtureProduct();
  const owner = await registerUser('7770001005');
  const stranger = await registerUser('7770001006');
  const addressId = await createAddress(owner.accessToken);

  const createResponse = await agent
    .post('/api/orders')
    .set('Authorization', `Bearer ${owner.accessToken}`)
    .send({
      addressId,
      paymentMode: 'cod',
      notes: 'Phase 7 order test',
      items: [{ productId, quantity: 3, variantKey: '2_kg' }],
    });

  assert.equal(createResponse.status, 201, createResponse.text);
  const orderId = createResponse.body.data.id;
  assert.equal(createResponse.body.data.items.length, 1);

  const itemRows = await pool.query('select * from order_items where order_id = $1', [orderId]);
  assert.equal(itemRows.rowCount, 1);
  assert.equal(itemRows.rows[0].quantity, 3);

  const strangerRead = await agent
    .get(`/api/orders/${orderId}`)
    .set('Authorization', `Bearer ${stranger.accessToken}`);
  assert.equal(strangerRead.status, 404);
});

test('admin auth supports login, refresh, logout and validates credentials', async () => {
  const email = `phase8-auth-${Date.now()}@vyparhub.test`;
  const session = await createAdminSession({ email });
  assert.equal(session.admin.email, email);
  assert.ok(session.accessToken);
  assert.ok(session.refreshToken);

  const refreshResponse = await agent
    .post('/api/admin/auth/refresh')
    .send({ refreshToken: session.refreshToken });
  assert.equal(refreshResponse.status, 200, refreshResponse.text);
  assert.ok(refreshResponse.body.data.accessToken);

  const logoutResponse = await agent
    .post('/api/admin/auth/logout')
    .send({ refreshToken: refreshResponse.body.data.refreshToken });
  assert.equal(logoutResponse.status, 200, logoutResponse.text);

  const invalid = await agent
    .post('/api/admin/auth/login')
    .send({ email, password: 'wrong' });
  assert.equal(invalid.status, 401);
});

test('admin RBAC denies missing permissions and admin validation errors are surfaced', async () => {
  const limited = await createAdminSession({
    email: `phase8-limited-${Date.now()}@vyparhub.test`,
    permissions: [{ module: 'categories', action: 'view' }],
  });

  const denied = await agent
    .post('/api/admin/categories')
    .set('Authorization', `Bearer ${limited.accessToken}`)
    .send({ slug: `phase7-denied-${Date.now()}`, nameEn: 'Denied' });
  assert.equal(denied.status, 403);

  const superAdmin = await createAdminSession({
    email: `phase8-validation-${Date.now()}@vyparhub.test`,
  });
  const invalid = await agent
    .post('/api/admin/categories')
    .set('Authorization', `Bearer ${superAdmin.accessToken}`)
    .send({ nameEn: '' });
  assert.equal(invalid.status, 422);
});

test('admin catalog CRUD creates products and variants with permission and validation coverage', async () => {
  const admin = await createAdminSession({
    email: `phase8-catalog-${Date.now()}@vyparhub.test`,
  });
  const token = admin.accessToken;

  const brand = await agent
    .post('/api/admin/brands')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: `Phase 8 Brand ${Date.now()}`, logoUrl: 'brands/coke.png', status: 'active' });
  assert.equal(brand.status, 201, brand.text);

  const { product, variant } = await createAdminProductWithVariant(token);
  assert.ok(product.id);
  assert.ok(variant.id);

  const updateVariant = await agent
    .put(`/api/admin/products/${product.id}/variants/${variant.id}`)
    .set('Authorization', `Bearer ${token}`)
    .send({
      variantName: '1L',
      sku: variant.sku,
      mrp: 105,
      sellingPrice: 79,
      stockQuantity: 4,
      unit: 'l',
      isDefault: true,
      status: 'active',
    });
  assert.equal(updateVariant.status, 200, updateVariant.text);
  assert.equal(Number(updateVariant.body.data.stock_quantity), 4);

  const invalidProduct = await agent
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${token}`)
    .send({ nameEn: 'Missing Category' });
  assert.equal(invalidProduct.status, 422);

  const limited = await createAdminSession({
    email: `phase8-catalog-denied-${Date.now()}@vyparhub.test`,
    permissions: [{ module: 'products', action: 'view' }],
  });
  const denied = await agent
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${limited.accessToken}`)
    .send({ nameEn: 'Denied', categoryId: product.category_id });
  assert.equal(denied.status, 403);
});

test('admin CSV import reactivates soft-deleted products instead of duplicating SKU rows', async () => {
  const admin = await createAdminSession({
    email: `phase8-import-${Date.now()}@vyparhub.test`,
  });
  const token = admin.accessToken;
  const key = `phase-import-${Date.now()}`;
  const csv = [
    'product_sku,name_en,category,brand,variant_name,sku,mrp,selling_price,cost_price,stock_quantity,unit,pack_quantity,status',
    `${key},Phase Import Cola,Phase Import Drinks,Phase Import Brand,Pack of 12,${key}-v1,120,90,70,10,pcs,12,active`,
  ].join('\n');

  const firstImport = await agent
    .post('/api/admin/products/import')
    .set('Authorization', `Bearer ${token}`)
    .send({ csv });
  assert.equal(firstImport.status, 200, firstImport.text);
  assert.equal(firstImport.body.data.created, 1);
  assert.equal(firstImport.body.data.updated, 0);

  const productsAfterCreate = await agent
    .get('/api/admin/products')
    .set('Authorization', `Bearer ${token}`);
  const createdProduct = productsAfterCreate.body.data.find((product) => product.sku === key);
  assert.ok(createdProduct?.id);

  const softDelete = await agent
    .delete(`/api/admin/products/${createdProduct.id}`)
    .set('Authorization', `Bearer ${token}`);
  assert.equal(softDelete.status, 200, softDelete.text);

  const correctedCsv = csv.replace('Phase Import Cola', 'Phase Import Cola Corrected').replace(',90,', ',95,');
  const secondImport = await agent
    .post('/api/admin/products/import')
    .set('Authorization', `Bearer ${token}`)
    .send({ csv: correctedCsv });
  assert.equal(secondImport.status, 200, secondImport.text);
  assert.equal(secondImport.body.data.created, 0);
  assert.equal(secondImport.body.data.updated, 1);

  const productsAfterReimport = await agent
    .get('/api/admin/products')
    .set('Authorization', `Bearer ${token}`);
  const reactivated = productsAfterReimport.body.data.find((product) => product.sku === key);
  assert.equal(reactivated?.is_active, true);
  assert.equal(reactivated?.name_en, 'Phase Import Cola Corrected');
  assert.equal(
    Number((reactivated.variants || []).find((variant) => variant.sku === `${key}-v1`)?.selling_price),
    95,
  );
});

test('admin coupon, home section, delivery zone, and loyalty routes validate and enforce permissions', async () => {
  const admin = await createAdminSession({
    email: `phase8-merch-${Date.now()}@vyparhub.test`,
  });
  const token = admin.accessToken;
  const { product } = await createAdminProductWithVariant(token);

  const coupon = await agent
    .post('/api/admin/offers')
    .set('Authorization', `Bearer ${token}`)
    .send({
      title: `Phase 8 Coupon ${Date.now()}`,
      subtitle: 'Integration coupon',
      couponCode: `PHASE8${Date.now()}`,
      discountPercent: 10,
      appliesTo: 'all',
      isActive: true,
    });
  assert.equal(coupon.status, 201, coupon.text);

  const tier = await agent
    .post('/api/admin/loyalty/tiers')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: `Phase 8 Silver ${Date.now()}`, minPoints: 100, benefitsJson: { cashback: 1 } });
  assert.equal(tier.status, 201, tier.text);

  const rule = await agent
    .post('/api/admin/loyalty/rules')
    .set('Authorization', `Bearer ${token}`)
    .send({ action: `phase8_order_${Date.now()}`, pointsAwarded: 10, active: true });
  assert.equal(rule.status, 201, rule.text);

  const reward = await agent
    .post('/api/admin/loyalty/rewards')
    .set('Authorization', `Bearer ${token}`)
    .send({ title: `Phase 8 Reward ${Date.now()}`, pointsCost: 50, rewardType: 'coupon', rewardValueJson: { code: 'P8' }, active: true });
  assert.equal(reward.status, 201, reward.text);

  const zone = await agent
    .post('/api/admin/delivery-zones')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: `Phase 8 Zone ${Date.now()}`, pincodes: '110001,110002', estimatedDeliveryMinutes: 120, deliveryFee: 20, freeDeliveryMinOrder: 999, active: true });
  assert.equal(zone.status, 201, zone.text);

  const section = await agent
    .post('/api/admin/home-sections')
    .set('Authorization', `Bearer ${token}`)
    .send({ sectionKey: 'top_deals', title: `Phase 8 Top Deals ${Date.now()}`, displayOrder: 1, active: true, items: [{ productId: product.id }] });
  assert.equal(section.status, 201, section.text);

  const invalidReward = await agent
    .post('/api/admin/loyalty/rewards')
    .set('Authorization', `Bearer ${token}`)
    .send({ title: `Phase 8 Bad Reward ${Date.now()}`, rewardType: 'not-valid' });
  assert.equal(invalidReward.status, 422);

  const limited = await createAdminSession({
    email: `phase8-merch-denied-${Date.now()}@vyparhub.test`,
    permissions: [{ module: 'rewards', action: 'view' }],
  });
  const denied = await agent
    .post('/api/admin/loyalty/tiers')
    .set('Authorization', `Bearer ${limited.accessToken}`)
    .send({ name: `Phase 8 Denied ${Date.now()}` });
  assert.equal(denied.status, 403);
});

test('admin order status, refund approval, and wallet adjustment routes enforce workflow rules', async () => {
  const productId = await createFixtureProduct();
  const customer = await registerUser('7770001008');
  const addressId = await createAddress(customer.accessToken);
  const orderResponse = await agent
    .post('/api/orders')
    .set('Authorization', `Bearer ${customer.accessToken}`)
    .send({
      addressId,
      paymentMode: 'cod',
      items: [{ productId, quantity: 1 }],
    });
  assert.equal(orderResponse.status, 201, orderResponse.text);
  const orderId = orderResponse.body.data.id;

  const refundResponse = await agent
    .post(`/api/orders/${orderId}/refund`)
    .set('Authorization', `Bearer ${customer.accessToken}`)
    .send({ reason: 'Damaged product', refundMethod: 'wallet' });
  assert.equal(refundResponse.status, 422);

  const admin = await createAdminSession({
    email: `phase8-orders-${Date.now()}@vyparhub.test`,
  });
  const token = admin.accessToken;
  const metricsBeforeStatusChanges = await dashboardOrderMetrics(token);

  const invalidStatus = await agent
    .patch(`/api/admin/orders/${orderId}/status`)
    .set('Authorization', `Bearer ${token}`)
    .send({});
  assert.equal(invalidStatus.status, 422);

  const confirmed = await agent
    .patch(`/api/admin/orders/${orderId}/status`)
    .set('Authorization', `Bearer ${token}`)
    .send({ status: 'confirmed' });
  assert.equal(confirmed.status, 200, confirmed.text);
  const metricsAfterConfirm = await dashboardOrderMetrics(token);
  assert.equal(
    metricsAfterConfirm.grossSales,
    metricsBeforeStatusChanges.grossSales,
    'confirmed orders must not count as sales',
  );
  assert.ok(
    metricsAfterConfirm.pendingRevenue >= metricsBeforeStatusChanges.pendingRevenue,
    'confirmed orders should stay in pending revenue until delivered',
  );

  const invalidTransition = await agent
    .patch(`/api/admin/orders/${orderId}/status`)
    .set('Authorization', `Bearer ${token}`)
    .send({ status: 'placed' });
  assert.equal(invalidTransition.status, 422);

  for (const status of ['packed', 'shipped', 'out_for_delivery', 'delivered']) {
    const response = await agent
      .patch(`/api/admin/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status });
    assert.equal(response.status, 200, response.text);
  }
  const metricsAfterDelivery = await dashboardOrderMetrics(token);
  assert.ok(
    metricsAfterDelivery.grossSales >= metricsBeforeStatusChanges.grossSales + Number(orderResponse.body.data.total || 0),
    'delivered orders must count as gross sales',
  );
  assert.ok(
    metricsAfterDelivery.deliveredCount >= metricsBeforeStatusChanges.deliveredCount + 1,
    'delivered order count should increase after delivery',
  );

  const refund = await agent
    .post(`/api/orders/${orderId}/refund`)
    .set('Authorization', `Bearer ${customer.accessToken}`)
    .send({ reason: 'Damaged product', refundMethod: 'wallet' });
  assert.equal(refund.status, 201, refund.text);

  const approved = await agent
    .post(`/api/admin/refunds/${refund.body.data.id}/approve`)
    .set('Authorization', `Bearer ${token}`)
    .send({ notes: 'Approved by test' });
  assert.equal(approved.status, 200, approved.text);
  const metricsAfterRefund = await dashboardOrderMetrics(token);
  assert.ok(
    metricsAfterRefund.refundedAmount >= metricsAfterDelivery.refundedAmount + Number(refund.body.data.amount || 0),
    'approved wallet refunds should appear as refunded amount',
  );
  assert.ok(
    metricsAfterRefund.netSales <= metricsAfterDelivery.netSales,
    'net sales should not increase after a refund',
  );

  const directRefundOrder = await agent
    .post('/api/orders')
    .set('Authorization', `Bearer ${customer.accessToken}`)
    .send({
      addressId,
      paymentMode: 'cod',
      items: [{ productId, quantity: 2 }],
    });
  assert.equal(directRefundOrder.status, 201, directRefundOrder.text);
  const directOrderId = directRefundOrder.body.data.id;
  for (const status of ['confirmed', 'packed', 'shipped', 'out_for_delivery', 'delivered']) {
    const response = await agent
      .patch(`/api/admin/orders/${directOrderId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status });
    assert.equal(response.status, 200, response.text);
  }
  const directAmount = Math.max(1, Number(directRefundOrder.body.data.total || 0) / 2);
  const idempotencyKey = crypto.randomUUID();
  const directRefund = await agent
    .post(`/api/admin/orders/${directOrderId}/refunds`)
    .set('Authorization', `Bearer ${token}`)
    .set('Idempotency-Key', idempotencyKey)
    .send({
      idempotencyKey,
      amount: directAmount,
      destination: 'wallet',
      reason: 'Customer request',
      notes: 'Partial refund test',
    });
  assert.equal(directRefund.status, 201, directRefund.text);
  assert.equal(directRefund.body.meta.order.status, 'partially_refunded');

  const duplicateRefund = await agent
    .post(`/api/admin/orders/${directOrderId}/refunds`)
    .set('Authorization', `Bearer ${token}`)
    .set('Idempotency-Key', idempotencyKey)
    .send({
      idempotencyKey,
      amount: directAmount,
      destination: 'wallet',
      reason: 'Customer request',
    });
  assert.equal(duplicateRefund.status, 200, duplicateRefund.text);
  assert.equal(duplicateRefund.body.data.id, directRefund.body.data.id);

  const overRefund = await agent
    .post(`/api/admin/orders/${directOrderId}/refunds`)
    .set('Authorization', `Bearer ${token}`)
    .set('Idempotency-Key', crypto.randomUUID())
    .send({
      amount: Number(directRefundOrder.body.data.total || 0) * 2,
      destination: 'wallet',
      reason: 'Too much',
    });
  assert.equal(overRefund.status, 422);

  const cancelCustomer = await registerUser('7770001018');
  const cancelAddressId = await createAddress(cancelCustomer.accessToken);
  const cancelOrder = await agent
    .post('/api/orders')
    .set('Authorization', `Bearer ${cancelCustomer.accessToken}`)
    .send({
      addressId: cancelAddressId,
      paymentMode: 'cod',
      items: [{ productId, quantity: 1 }],
    });
  assert.equal(cancelOrder.status, 201, cancelOrder.text);
  const beforeCancelMetrics = await dashboardOrderMetrics(token);
  const cancelled = await agent
    .post(`/api/orders/${cancelOrder.body.data.id}/cancel`)
    .set('Authorization', `Bearer ${cancelCustomer.accessToken}`)
    .send({ reason: 'Ordered by mistake' });
  assert.equal(cancelled.status, 200, cancelled.text);
  const afterCancelMetrics = await dashboardOrderMetrics(token);
  assert.equal(
    afterCancelMetrics.grossSales,
    beforeCancelMetrics.grossSales,
    'cancelled orders must never count as sales',
  );
  assert.ok(
    afterCancelMetrics.cancelledValue >= beforeCancelMetrics.cancelledValue + Number(cancelOrder.body.data.total || 0),
    'cancelled order value should be reported separately',
  );

  const wallet = await agent
    .post(`/api/admin/wallet/customers/${customer.user.id}/transactions`)
    .set('Authorization', `Bearer ${token}`)
    .send({ type: 'credit', amount: 25, reason: 'admin_adjustment' });
  assert.equal(wallet.status, 201, wallet.text);

  const limited = await createAdminSession({
    email: `phase8-orders-denied-${Date.now()}@vyparhub.test`,
    permissions: [{ module: 'orders', action: 'view' }],
  });
  const denied = await agent
    .patch(`/api/admin/orders/${orderId}/status`)
    .set('Authorization', `Bearer ${limited.accessToken}`)
    .send({ status: 'delivered' });
  assert.equal(denied.status, 403);

  const deniedRefund = await agent
    .post(`/api/admin/orders/${directOrderId}/refunds`)
    .set('Authorization', `Bearer ${limited.accessToken}`)
    .set('Idempotency-Key', crypto.randomUUID())
    .send({ amount: 1, destination: 'wallet', reason: 'Denied' });
  assert.equal(deniedRefund.status, 403);
});

test('socket namespaces require JWTs and deliver admin order events', async () => {
  const admin = await createAdminSession({
    email: `phase8-socket-${Date.now()}@vyparhub.test`,
  });
  const productId = await createFixtureProduct();
  const customer = await registerUser('7770001009');
  const addressId = await createAddress(customer.accessToken);

  const server = http.createServer(app);
  initRealtime(server, '*');
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  const rejected = socketClient(`${baseUrl}/admin`, {
    auth: { token: 'bad-token' },
    reconnection: false,
    transports: ['websocket'],
  });
  await new Promise((resolve) => rejected.once('connect_error', resolve));
  rejected.close();

  const adminSocket = socketClient(`${baseUrl}/admin`, {
    auth: { token: admin.accessToken },
    reconnection: false,
    transports: ['websocket'],
  });
  await new Promise((resolve, reject) => {
    adminSocket.once('connect', resolve);
    adminSocket.once('connect_error', reject);
  });

  const eventPromise = new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Timed out waiting for order.created')), 2000);
    adminSocket.once('order.created', (payload) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });

  const orderResponse = await request(baseUrl)
    .post('/api/orders')
    .set('Authorization', `Bearer ${customer.accessToken}`)
    .send({
      addressId,
      paymentMode: 'cod',
      items: [{ productId, quantity: 1 }],
    });
  assert.equal(orderResponse.status, 201, orderResponse.text);

  const payload = await eventPromise;
  assert.equal(payload.orderId, orderResponse.body.data.id);

  adminSocket.close();
  await new Promise((resolve) => server.close(resolve));
});

test('Razorpay webhook rejects tampered payloads and accepts valid signatures', async () => {
  const productId = await createFixtureProduct();
  const owner = await registerUser('7770001007');
  const addressId = await createAddress(owner.accessToken);
  const orderResponse = await agent
    .post('/api/orders')
    .set('Authorization', `Bearer ${owner.accessToken}`)
    .send({
      addressId,
      notes: 'Webhook test',
      items: [{ productId, quantity: 1 }],
    });
  assert.equal(orderResponse.status, 201, orderResponse.text);
  const orderId = orderResponse.body.data.id;

  const payload = JSON.stringify({
    event: 'payment.captured',
    payload: {
      payment: {
        entity: {
          id: `pay_${testPrefix}`,
          order_id: `order_${testPrefix}`,
          amount: 9000,
          notes: { internalOrderId: orderId },
        },
      },
    },
  });
  const signature = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(payload)
    .digest('hex');

  const tampered = await agent
    .post('/api/payments/webhook')
    .set('Content-Type', 'application/json')
    .set('x-razorpay-signature', 'bad-signature')
    .send(payload);
  assert.equal(tampered.status, 400);

  const valid = await agent
    .post('/api/payments/webhook')
    .set('Content-Type', 'application/json')
    .set('x-razorpay-signature', signature)
    .send(payload);
  assert.equal(valid.status, 200, valid.text);
  assert.equal(valid.body.data.status, 'confirmed');

  const order = await pool.query('select status from orders where id = $1', [orderId]);
  assert.equal(order.rows[0].status, 'confirmed');
});
