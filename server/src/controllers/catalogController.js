import * as repo from "../repositories/catalogRepository.js";
import { notFound } from "../utils/apiError.js";

export async function getProducts(req, res, next) {
  try {
    res.json({ success: true, data: await repo.products(req.query) });
  } catch (error) {
    next(error);
  }
}

export async function getProduct(req, res, next) {
  try {
    const product = await repo.productById(req.params.id);

    if (!product) {
      throw notFound("Product");
    }

    res.json({ success: true, data: product });
  } catch (error) {
    next(error);
  }
}

export async function getCategories(req, res, next) {
  try {
    res.json({ success: true, data: await repo.categories(req.query) });
  } catch (error) {
    next(error);
  }
}

export async function getOffers(req, res, next) {
  try {
    res.json({ success: true, data: await repo.offers() });
  } catch (error) {
    next(error);
  }
}

export async function getHomeSections(req, res, next) {
  try {
    res.json({ success: true, data: await repo.homeSections(req.query) });
  } catch (error) {
    next(error);
  }
}

export async function getDeliveryContext(req, res, next) {
  try {
    res.json({ success: true, data: await repo.deliveryContext(req.query) });
  } catch (error) {
    next(error);
  }
}
