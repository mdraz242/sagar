import * as auth from "../services/authService.js";
import * as otp from "../services/otpService.js";

export async function register(req, res, next) {
  try {
    res
      .status(201)
      .json({ success: true, data: await auth.register(req.body) });
  } catch (error) {
    next(error);
  }
}

export async function login(req, res, next) {
  try {
    res.json({ success: true, data: await auth.login(req.body) });
  } catch (error) {
    next(error);
  }
}

export async function lookup(req, res, next) {
  try {
    res.json({ success: true, data: await auth.lookup(req.query) });
  } catch (error) {
    next(error);
  }
}

export async function refresh(req, res, next) {
  try {
    res.json({ success: true, data: await auth.refresh(req.body) });
  } catch (error) {
    next(error);
  }
}

export async function requestOtp(req, res, next) {
  try {
    res
      .status(201)
      .json({ success: true, data: await otp.requestOtp(req.body) });
  } catch (error) {
    next(error);
  }
}

export async function resendOtp(req, res, next) {
  try {
    res
      .status(201)
      .json({ success: true, data: await otp.requestOtp(req.body) });
  } catch (error) {
    next(error);
  }
}

export async function verifyOtp(req, res, next) {
  try {
    res.json({ success: true, data: await otp.verifyOtp(req.body) });
  } catch (error) {
    next(error);
  }
}

export async function logout(req, res) {
  res.json({ success: true, data: { message: "Logged out" } });
}
