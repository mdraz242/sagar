import { ApiError } from "../utils/apiError.js";

export function notFoundHandler(req, res, next) {
  next(new ApiError(404, "Route not found"));
}

function postgresMessage(err) {
  if (err.code === "23505") {
    return "A record with the same unique value already exists";
  }
  if (err.code === "23503") return "Selected linked record does not exist";
  if (err.code === "23502") return "Please fill all required fields";
  if (err.code === "22P02") {
    return "Please recheck your delivery address or selected product option";
  }
  if (err.code === "23514") return "Invalid value for this field";
  return null;
}

export function errorHandler(err, req, res, next) {
  const mapped = postgresMessage(err);
  const status = err.status || (mapped ? 422 : 500);
  res.status(status).json({
    success: false,
    error: {
      message: mapped || err.message || "Internal server error",
      details: err.details,
    },
  });
}
