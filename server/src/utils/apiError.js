export class ApiError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}
export const notFound = (name = "Resource") =>
  new ApiError(404, `${name} not found`);
