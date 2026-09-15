import { query } from "../config/db.js";
import { Router } from "express";
import rateLimit from "express-rate-limit";
import * as auth from "../controllers/authController.js";
import * as catalog from "../controllers/catalogController.js";
import * as cart from "../controllers/cartController.js";
import * as orders from "../controllers/orderController.js";
import * as addresses from "../controllers/addressController.js";
import * as profile from "../controllers/profileController.js";
import * as admin from "../controllers/admin/index.js";
import * as payments from "../controllers/paymentController.js";
import * as adminAuth from "../controllers/adminAuthController.js";
import { authenticate } from "../middleware/auth.js";
import {
  requireAdminAuth,
  requireAnyPermission,
  requirePermission,
} from "../middleware/adminAuth.js";
import {
  loginSchema,
  registerSchema,
  validate,
} from "../validators/authValidator.js";

const router = Router();

// ---------------------------------------------------------------------------
// Banner helpers (previously missing — added to fix the /admin/banners routes
// and the crash caused by the undefined `bannerUpload` middleware)
// ---------------------------------------------------------------------------

const bannerColumns = `id, title, subtitle, image_url, cta_text, cta_action, location, sort_order, active, starts_at, ends_at, config, created_at, updated_at`;

function parseBannerBody(body = {}) {
  return {
    title: (body.title || "").trim(),
    subtitle: body.subtitle ? String(body.subtitle).trim() : null,
    image_url: (body.image_url || body.imageUrl || "").trim(),
    cta_text:
      body.cta_text || body.ctaText
        ? String(body.cta_text || body.ctaText).trim()
        : null,
    cta_action:
      body.cta_action || body.ctaAction
        ? String(body.cta_action || body.ctaAction).trim()
        : null,
    location: body.location ? String(body.location).trim() : "home",
    sort_order: Number.isFinite(Number(body.sort_order))
      ? Number(body.sort_order)
      : 0,
    active: body.active === undefined ? true : Boolean(body.active),
    starts_at: body.starts_at || body.startsAt || "",
    ends_at: body.ends_at || body.endsAt || "",
    config:
      typeof body.config === "object" && body.config !== null
        ? body.config
        : {},
  };
}

function emitBannerChange(req, action, banner) {
  const io = req.app?.get?.("io");
  if (io && typeof io.emit === "function") {
    io.emit("banners:changed", { action, banner });
  }
}

// ---------------------------------------------------------------------------

const otpRequestLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 3,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body?.phone || req.ip,
  message: {
    success: false,
    error: {
      message:
        "Too many OTP requests. Please wait before requesting another code.",
    },
  },
});

const loginLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body?.phone || req.ip,
  message: {
    success: false,
    error: {
      message: "Too many login attempts. Please wait before trying again.",
    },
  },
});

router.post("/auth/register", validate(registerSchema), auth.register);
router.post("/auth/login", loginLimiter, validate(loginSchema), auth.login);
router.get("/auth/lookup", auth.lookup);
router.post("/auth/refresh", auth.refresh);
router.post("/auth/otp/send", otpRequestLimiter, auth.requestOtp);
router.post("/auth/otp/resend", otpRequestLimiter, auth.resendOtp);
router.post("/auth/otp/request", otpRequestLimiter, auth.requestOtp);
router.post("/auth/otp/verify", auth.verifyOtp);
router.post("/auth/logout", authenticate, auth.logout);

router.get("/products", catalog.getProducts);
router.get("/products/:id", catalog.getProduct);
router.get("/categories", catalog.getCategories);
router.get("/offers", catalog.getOffers);
router.get("/home-sections", catalog.getHomeSections);
router.get("/homepage-sections", catalog.getHomeSections);
router.get("/delivery-context", catalog.getDeliveryContext);

router.get("/cart", authenticate, cart.getCart);
router.post("/cart/add", authenticate, cart.add);
router.post("/cart/remove", authenticate, cart.remove);

router.get("/addresses", authenticate, addresses.listAddresses);
router.post("/addresses", authenticate, addresses.createAddress);
router.put("/addresses/:id", authenticate, addresses.updateAddress);
router.patch(
  "/addresses/:id/default",
  authenticate,
  addresses.setDefaultAddress,
);
router.delete("/addresses/:id", authenticate, addresses.deleteAddress);

router.post("/orders", authenticate, orders.createOrder);
router.get("/orders", authenticate, orders.listOrders);
router.get("/orders/:id", authenticate, orders.getOrder);
router.post("/orders/:id/cancel", authenticate, orders.cancelOrder);
router.put("/orders/:id/items", authenticate, orders.updateOrderItems);
router.post("/orders/:id/refund", authenticate, orders.requestRefund);

router.post(
  "/payments/create-order",
  authenticate,
  payments.createRazorpayOrder,
);
router.post("/payments/webhook", payments.webhook);

router.get("/profile", authenticate, profile.getProfile);
router.put("/profile", authenticate, profile.updateProfile);
router.delete("/profile/account", authenticate, profile.deleteAccount);

router.post("/admin/auth/login", loginLimiter, adminAuth.login);
router.post("/admin/auth/refresh", adminAuth.refresh);
router.post("/admin/auth/logout", adminAuth.logout);

router.get(
  "/admin/dashboard",
  requireAdminAuth,
  requirePermission("dashboard", "view"),
  admin.dashboard,
);
router.get(
  "/admin/search",
  requireAdminAuth,
  requirePermission("dashboard", "view"),
  admin.search,
);
router.get(
  "/admin/catalog/visibility",
  requireAdminAuth,
  requirePermission("products", "view"),
  admin.catalogVisibility,
);
router.get(
  "/admin/catalog/pricing-health",
  requireAdminAuth,
  requirePermission("products", "view"),
  admin.catalogPricingHealth,
);
router.get(
  "/admin/orders",
  requireAdminAuth,
  requirePermission("orders", "view"),
  admin.orders,
);
router.get(
  "/admin/orders/:id",
  requireAdminAuth,
  requirePermission("orders", "view"),
  admin.orderDetail,
);
router.patch(
  "/admin/orders/:id/status",
  requireAdminAuth,
  requirePermission("orders", "edit"),
  admin.updateOrderStatus,
);
router.post(
  "/admin/orders/:id/refunds",
  requireAdminAuth,
  requirePermission("returns", "edit"),
  admin.createRefund,
);
router.post(
  "/admin/refunds/:id/approve",
  requireAdminAuth,
  requirePermission("returns", "edit"),
  admin.approveRefund,
);
router.post(
  "/admin/refunds/:id/reject",
  requireAdminAuth,
  requirePermission("returns", "edit"),
  admin.rejectRefund,
);

router.get(
  "/admin/import-template/:type",
  requireAdminAuth,
  requirePermission("products", "import"),
  admin.importTemplate,
);
router.get(
  "/admin/products/export",
  requireAdminAuth,
  requirePermission("products", "export"),
  admin.exportProductsCsv,
);
router.post(
  "/admin/products/import",
  requireAdminAuth,
  requirePermission("products", "import"),
  admin.importProductsCsv,
);
router.post(
  "/admin/catalog/reset",
  requireAdminAuth,
  requirePermission("products", "delete"),
  admin.resetCatalog,
);
router.post(
  "/admin/brands/import",
  requireAdminAuth,
  requirePermission("brands", "add"),
  admin.importBrandsCsv,
);
router.post(
  "/admin/categories/import",
  requireAdminAuth,
  requirePermission("categories", "add"),
  admin.importCategoriesCsv,
);
router.get(
  "/admin/products",
  requireAdminAuth,
  requirePermission("products", "view"),
  admin.products,
);
router.post(
  "/admin/products",
  requireAdminAuth,
  requirePermission("products", "add"),
  admin.createProduct,
);
router.post(
  "/admin/products/bulk-delete",
  requireAdminAuth,
  requirePermission("products", "delete"),
  admin.bulkDeleteProducts,
);
router.put(
  "/admin/products/:id",
  requireAdminAuth,
  requirePermission("products", "edit"),
  admin.updateProduct,
);
router.delete(
  "/admin/products/:id",
  requireAdminAuth,
  requirePermission("products", "delete"),
  admin.deleteProduct,
);
router.get(
  "/admin/products/:id/variants",
  requireAdminAuth,
  requirePermission("products", "view"),
  admin.productVariants,
);
router.post(
  "/admin/products/:id/variants",
  requireAdminAuth,
  requirePermission("products", "add"),
  admin.createProductVariant,
);
router.put(
  "/admin/products/:id/variants/:variantId",
  requireAdminAuth,
  requirePermission("products", "edit"),
  admin.updateProductVariant,
);
router.delete(
  "/admin/products/:id/variants/:variantId",
  requireAdminAuth,
  requirePermission("products", "delete"),
  admin.deleteProductVariant,
);

router.get(
  "/admin/categories",
  requireAdminAuth,
  requirePermission("categories", "view"),
  admin.categories,
);
router.post(
  "/admin/categories",
  requireAdminAuth,
  requirePermission("categories", "add"),
  admin.createCategory,
);
router.post(
  "/admin/categories/bulk-delete",
  requireAdminAuth,
  requirePermission("categories", "delete"),
  admin.bulkDeleteCategories,
);
router.put(
  "/admin/categories/:id",
  requireAdminAuth,
  requirePermission("categories", "edit"),
  admin.updateCategory,
);
router.delete(
  "/admin/categories/:id",
  requireAdminAuth,
  requirePermission("categories", "delete"),
  admin.deleteCategory,
);
router.get(
  "/admin/brands",
  requireAdminAuth,
  requirePermission("brands", "view"),
  admin.brands,
);
router.post(
  "/admin/brands",
  requireAdminAuth,
  requirePermission("brands", "add"),
  admin.createBrand,
);
router.post(
  "/admin/brands/bulk-delete",
  requireAdminAuth,
  requirePermission("brands", "delete"),
  admin.bulkDeleteBrands,
);
router.put(
  "/admin/brands/:id",
  requireAdminAuth,
  requirePermission("brands", "edit"),
  admin.updateBrand,
);
router.delete(
  "/admin/brands/:id",
  requireAdminAuth,
  requirePermission("brands", "delete"),
  admin.deleteBrand,
);
router.get(
  "/admin/offers",
  requireAdminAuth,
  requirePermission("coupons", "view"),
  admin.offers,
);
router.post(
  "/admin/offers",
  requireAdminAuth,
  requirePermission("coupons", "add"),
  admin.createOffer,
);
router.put(
  "/admin/offers/:id",
  requireAdminAuth,
  requirePermission("coupons", "edit"),
  admin.updateOffer,
);
router.delete(
  "/admin/offers/:id",
  requireAdminAuth,
  requirePermission("coupons", "delete"),
  admin.deleteOffer,
);
router.get(
  "/admin/customers",
  requireAdminAuth,
  requirePermission("customers", "view"),
  admin.customers,
);
router.get(
  "/admin/customers/:id",
  requireAdminAuth,
  requirePermission("customers", "view"),
  admin.customerDetail,
);
router.get(
  "/admin/wallet/customers/:id/transactions",
  requireAdminAuth,
  requirePermission("customers", "view"),
  admin.customerWalletTransactions,
);
router.post(
  "/admin/wallet/customers/:id/transactions",
  requireAdminAuth,
  requirePermission("customers", "edit"),
  admin.adjustCustomerWallet,
);
router.post(
  "/admin/customers/:id/points",
  requireAdminAuth,
  requirePermission("customers", "edit"),
  admin.adjustCustomerPoints,
);
router.get(
  "/admin/reports",
  requireAdminAuth,
  requirePermission("reports", "view"),
  admin.reports,
);
router.get(
  "/admin/payments",
  requireAdminAuth,
  requirePermission("payments", "view"),
  admin.payments,
);
router.get(
  "/admin/payouts",
  requireAdminAuth,
  requirePermission("payouts", "view"),
  admin.payouts,
);
router.get(
  "/admin/returns",
  requireAdminAuth,
  requirePermission("returns", "view"),
  admin.returnsRefunds,
);
router.patch(
  "/admin/returns/:id/status",
  requireAdminAuth,
  requirePermission("returns", "edit"),
  admin.updateReturnStatus,
);
router.get(
  "/admin/support",
  requireAdminAuth,
  requirePermission("support", "view"),
  admin.supportTickets,
);
router.get(
  "/admin/users",
  requireAdminAuth,
  requirePermission("users", "view"),
  admin.adminUsers,
);
router.post(
  "/admin/users",
  requireAdminAuth,
  requirePermission("users", "add"),
  admin.createAdminUser,
);
router.put(
  "/admin/users/:id",
  requireAdminAuth,
  requirePermission("users", "edit"),
  admin.updateAdminUser,
);
router.get(
  "/admin/roles",
  requireAdminAuth,
  requirePermission("users", "view"),
  admin.roles,
);
router.post(
  "/admin/roles",
  requireAdminAuth,
  requirePermission("users", "add"),
  admin.createRole,
);
router.put(
  "/admin/roles/:id",
  requireAdminAuth,
  requirePermission("users", "edit"),
  admin.updateRole,
);
router.delete(
  "/admin/roles/:id",
  requireAdminAuth,
  requirePermission("users", "delete"),
  admin.deleteRole,
);
router.get(
  "/admin/logs",
  requireAdminAuth,
  requirePermission("logs", "view"),
  admin.activityLogs,
);
router.get(
  "/admin/settings",
  requireAdminAuth,
  requirePermission("settings", "view"),
  admin.settings,
);
router.put(
  "/admin/settings",
  requireAdminAuth,
  requirePermission("settings", "edit"),
  admin.saveSettings,
);
router.post(
  "/admin/notifications",
  requireAdminAuth,
  requirePermission("marketing", "add"),
  admin.sendNotification,
);
router.get(
  "/admin/notifications",
  requireAdminAuth,
  requirePermission("marketing", "view"),
  admin.notificationHistory,
);
router.get(
  "/admin/loyalty/tiers",
  requireAdminAuth,
  requirePermission("rewards", "view"),
  admin.loyaltyTiers,
);
router.post(
  "/admin/loyalty/tiers",
  requireAdminAuth,
  requirePermission("rewards", "add"),
  admin.createLoyaltyTier,
);
router.put(
  "/admin/loyalty/tiers/:id",
  requireAdminAuth,
  requirePermission("rewards", "edit"),
  admin.updateLoyaltyTier,
);
router.delete(
  "/admin/loyalty/tiers/:id",
  requireAdminAuth,
  requirePermission("rewards", "delete"),
  admin.deleteLoyaltyTier,
);
router.get(
  "/admin/loyalty/rules",
  requireAdminAuth,
  requirePermission("rewards", "view"),
  admin.loyaltyRules,
);
router.post(
  "/admin/loyalty/rules",
  requireAdminAuth,
  requirePermission("rewards", "add"),
  admin.createLoyaltyRule,
);
router.put(
  "/admin/loyalty/rules/:id",
  requireAdminAuth,
  requirePermission("rewards", "edit"),
  admin.updateLoyaltyRule,
);
router.delete(
  "/admin/loyalty/rules/:id",
  requireAdminAuth,
  requirePermission("rewards", "delete"),
  admin.deleteLoyaltyRule,
);
router.get(
  "/admin/loyalty/rewards",
  requireAdminAuth,
  requirePermission("rewards", "view"),
  admin.loyaltyRewards,
);
router.post(
  "/admin/loyalty/rewards",
  requireAdminAuth,
  requirePermission("rewards", "add"),
  admin.createLoyaltyReward,
);
router.put(
  "/admin/loyalty/rewards/:id",
  requireAdminAuth,
  requirePermission("rewards", "edit"),
  admin.updateLoyaltyReward,
);
router.delete(
  "/admin/loyalty/rewards/:id",
  requireAdminAuth,
  requirePermission("rewards", "delete"),
  admin.deleteLoyaltyReward,
);
router.get(
  "/admin/referrals",
  requireAdminAuth,
  requirePermission("rewards", "view"),
  admin.referrals,
);
router.put(
  "/admin/referrals/settings",
  requireAdminAuth,
  requirePermission("rewards", "edit"),
  admin.saveReferralSettings,
);
router.get(
  "/admin/home-sections",
  requireAdminAuth,
  requirePermission("merchandising", "view"),
  admin.homeSections,
);
router.post(
  "/admin/home-sections",
  requireAdminAuth,
  requirePermission("merchandising", "add"),
  admin.saveHomeSection,
);
router.put(
  "/admin/home-sections/:id",
  requireAdminAuth,
  requirePermission("merchandising", "edit"),
  admin.saveHomeSection,
);
router.delete(
  "/admin/home-sections/:id",
  requireAdminAuth,
  requirePermission("merchandising", "delete"),
  admin.deleteHomeSection,
);
router.get(
  "/admin/delivery-zones",
  requireAdminAuth,
  requirePermission("merchandising", "view"),
  admin.deliveryZones,
);
router.post(
  "/admin/delivery-zones",
  requireAdminAuth,
  requirePermission("merchandising", "add"),
  admin.createDeliveryZone,
);
router.put(
  "/admin/delivery-zones/:id",
  requireAdminAuth,
  requirePermission("merchandising", "edit"),
  admin.updateDeliveryZone,
);
router.delete(
  "/admin/delivery-zones/:id",
  requireAdminAuth,
  requirePermission("merchandising", "delete"),
  admin.deleteDeliveryZone,
);
router.post(
  "/admin/uploads",
  requireAdminAuth,
  requireAnyPermission(
    { module: "products", action: "add" },
    { module: "marketing", action: "add" },
    { module: "coupons", action: "add" },
    { module: "banners", action: "add" },
  ),
  admin.uploadMiddleware,
  admin.upload,
);

// BANNER_MANAGER_ROUTES
router.get("/banners", async (_req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT ${bannerColumns}
         FROM banners
        WHERE archived_at IS NULL
          AND active = TRUE
          AND (starts_at IS NULL OR starts_at <= NOW())
          AND (ends_at IS NULL OR ends_at >= NOW())
        ORDER BY sort_order ASC, created_at DESC`
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    next(err);
  }
});

router.get(
  "/admin/banners",
  requireAdminAuth,
  requirePermission("banners", "view"),
  async (_req, res, next) => {
    try {
      const { rows } = await query(
        `SELECT ${bannerColumns}
           FROM banners
          WHERE archived_at IS NULL
          ORDER BY sort_order ASC, created_at DESC`
      );
      res.json({ success: true, data: rows });
    } catch (err) {
      next(err);
    }
  },
);

// NOTE: banner image uploads reuse the shared POST /admin/uploads route
// declared above (admin.uploadMiddleware / admin.upload), which already
// includes the "banners" permission in requireAnyPermission. The admin UI
// should call that endpoint to get back an image URL, then submit that URL
// as `image_url` here. The previous duplicate route here referenced an
// undefined `bannerUpload` middleware and has been removed.

router.post(
  "/admin/banners",
  requireAdminAuth,
  requirePermission("banners", "add"),
  async (req, res, next) => {
    try {
      const payload = parseBannerBody(req.body);
      if (!payload.title) {
        return res
          .status(400)
          .json({ success: false, error: { message: "Banner title is required" } });
      }
      if (!payload.image_url) {
        return res
          .status(400)
          .json({ success: false, error: { message: "Banner image is required" } });
      }
      const params = [
        payload.title,
        payload.subtitle,
        payload.image_url,
        payload.cta_text,
        payload.cta_action,
        payload.location,
        payload.sort_order,
        payload.active,
        payload.starts_at,
        payload.ends_at,
        JSON.stringify(payload.config || {}),
      ];
      const { rows } = await query(
        `INSERT INTO banners (title, subtitle, image_url, cta_text, cta_action, location, sort_order, active, starts_at, ends_at, config)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NULLIF($9, '')::timestamptz, NULLIF($10, '')::timestamptz, COALESCE($11::jsonb, '{}'::jsonb))
         RETURNING ${bannerColumns}`,
        params,
      );
      emitBannerChange(req, "created", rows[0]);
      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      next(err);
    }
  },
);

router.put(
  "/admin/banners/:id",
  requireAdminAuth,
  requirePermission("banners", "edit"),
  async (req, res, next) => {
    try {
      const payload = parseBannerBody(req.body);
      if (!payload.title) {
        return res
          .status(400)
          .json({ success: false, error: { message: "Banner title is required" } });
      }
      if (!payload.image_url) {
        return res
          .status(400)
          .json({ success: false, error: { message: "Banner image is required" } });
      }
      const params = [
        payload.title,
        payload.subtitle,
        payload.image_url,
        payload.cta_text,
        payload.cta_action,
        payload.location,
        payload.sort_order,
        payload.active,
        payload.starts_at,
        payload.ends_at,
        JSON.stringify(payload.config || {}),
        req.params.id,
      ];
      const { rows } = await query(
        `UPDATE banners
            SET title = $1,
                subtitle = $2,
                image_url = $3,
                cta_text = $4,
                cta_action = $5,
                location = $6,
                sort_order = $7,
                active = $8,
                starts_at = NULLIF($9, '')::timestamptz,
                ends_at = NULLIF($10, '')::timestamptz,
                config = COALESCE($11::jsonb, '{}'::jsonb),
                updated_at = NOW()
          WHERE id = $12
            AND archived_at IS NULL
          RETURNING ${bannerColumns}`,
        params,
      );
      if (!rows[0])
        return res
          .status(404)
          .json({ success: false, error: { message: "Banner not found" } });
      emitBannerChange(req, "updated", rows[0]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      next(err);
    }
  },
);

router.delete(
  "/admin/banners/:id",
  requireAdminAuth,
  requirePermission("banners", "delete"),
  async (req, res, next) => {
    try {
      const { rows } = await query(
        `UPDATE banners
            SET active = FALSE,
                archived_at = NOW(),
                updated_at = NOW()
          WHERE id = $1
            AND archived_at IS NULL
          RETURNING ${bannerColumns}`,
        [req.params.id],
      );
      if (!rows[0])
        return res
          .status(404)
          .json({ success: false, error: { message: "Banner not found" } });
      emitBannerChange(req, "archived", rows[0]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      next(err);
    }
  },
);
// END_BANNER_MANAGER_ROUTES

export default router;
