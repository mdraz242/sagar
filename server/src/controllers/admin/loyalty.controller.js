import { listTable, createMapped, updateMapped, deleteMapped } from "./helpers.js";

export const loyaltyTiers = async (_req, res, next) => {
  try {
    await listTable(res, "loyalty_tiers", "min_points");
  } catch (e) {
    next(e);
  }
};

export const createLoyaltyTier = (req, res, next) =>
  createMapped(req, res, next, "loyaltyTiers", "loyalty_tier");

export const updateLoyaltyTier = (req, res, next) =>
  updateMapped(req, res, next, "loyaltyTiers", "loyalty_tier");

export const deleteLoyaltyTier = (req, res, next) =>
  deleteMapped(req, res, next, "loyaltyTiers", "loyalty_tier");

export const loyaltyRules = async (_req, res, next) => {
  try {
    await listTable(res, "loyalty_rules", "action");
  } catch (e) {
    next(e);
  }
};

export const createLoyaltyRule = (req, res, next) =>
  createMapped(req, res, next, "loyaltyRules", "loyalty_rule");

export const updateLoyaltyRule = (req, res, next) =>
  updateMapped(req, res, next, "loyaltyRules", "loyalty_rule");

export const deleteLoyaltyRule = (req, res, next) =>
  deleteMapped(req, res, next, "loyaltyRules", "loyalty_rule");

export const loyaltyRewards = async (_req, res, next) => {
  try {
    await listTable(res, "redeemable_rewards", "points_cost");
  } catch (e) {
    next(e);
  }
};

export const createLoyaltyReward = (req, res, next) =>
  createMapped(req, res, next, "loyaltyRewards", "redeemable_reward");

export const updateLoyaltyReward = (req, res, next) =>
  updateMapped(req, res, next, "loyaltyRewards", "redeemable_reward");

export const deleteLoyaltyReward = (req, res, next) =>
  deleteMapped(req, res, next, "loyaltyRewards", "redeemable_reward");

export const deliveryZones = async (_req, res, next) => {
  try {
    await listTable(res, "delivery_zones", "name");
  } catch (e) {
    next(e);
  }
};

export const createDeliveryZone = (req, res, next) =>
  createMapped(req, res, next, "deliveryZones", "delivery_zone");

export const updateDeliveryZone = (req, res, next) =>
  updateMapped(req, res, next, "deliveryZones", "delivery_zone");

export const deleteDeliveryZone = (req, res, next) =>
  deleteMapped(req, res, next, "deliveryZones", "delivery_zone");
