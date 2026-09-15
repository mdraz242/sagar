import { catalogVisibilityData, catalogPricingHealthData } from "./helpers.js";

export async function catalogVisibility(_req, res, next) {
  try {
    res.json({ success: true, data: await catalogVisibilityData() });
  } catch (e) {
    next(e);
  }
}

export async function catalogPricingHealth(_req, res, next) {
  try {
    res.json({ success: true, data: await catalogPricingHealthData() });
  } catch (e) {
    next(e);
  }
}
