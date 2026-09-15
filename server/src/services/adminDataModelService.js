import {
  createRecord,
  deleteRecord,
  getRecord,
  listRecords,
  reconcileWallet,
  refreshStartingPrice,
  updateRecord,
} from "../repositories/adminDataModelRepository.js";

export const adminDataModelService = {
  list: listRecords,
  get: getRecord,
  create: createRecord,
  update: updateRecord,
  delete: deleteRecord,
};

export async function createBrand(data) {
  return createRecord("brands", data);
}

export async function updateBrand(id, data) {
  return updateRecord("brands", id, data);
}

export async function createProductVariant(data) {
  const variant = await createRecord("productVariants", data);
  await refreshStartingPrice(variant.product_id);
  return variant;
}

export async function updateProductVariant(id, data) {
  const before = await getRecord("productVariants", id);
  const variant = await updateRecord("productVariants", id, data);
  if (variant?.product_id || before?.product_id) {
    await refreshStartingPrice(variant?.product_id || before.product_id);
  }
  return variant;
}

export async function createWalletAccount(customerId) {
  return createRecord("walletAccounts", { customer_id: customerId });
}

export async function recordWalletTransaction(data) {
  const transaction = await createRecord("walletTransactions", data);
  await reconcileWallet(transaction.wallet_account_id);
  return transaction;
}

export async function createLoyaltyTier(data) {
  return createRecord("loyaltyTiers", data);
}

export async function createLoyaltyRule(data) {
  return createRecord("loyaltyRules", data);
}

export async function recordLoyaltyLedger(data) {
  return createRecord("loyaltyLedger", data);
}

export async function createRedeemableReward(data) {
  return createRecord("redeemableRewards", data);
}

export async function createReferralCode(data) {
  return createRecord("referralCodes", data);
}

export async function recordReferralEvent(data) {
  return createRecord("referralEvents", data);
}

export async function createDeliveryZone(data) {
  return createRecord("deliveryZones", data);
}

export async function createHomeSection(data) {
  return createRecord("homeSections", data);
}

export async function addHomeSectionItem(data) {
  return createRecord("homeSectionItems", data);
}

export async function logAdminActivity(data) {
  return createRecord("adminActivityLog", data);
}

export async function logNotification(data) {
  return createRecord("notificationsLog", data);
}
