import { z } from "zod";
export const registerSchema = z.object({
  name: z.string().min(2),
  shopName: z.string().min(2),
  phone: z.string().min(10),
  password: z.string().min(6),
  address: z.string().min(3),
  area: z.string().min(2),
  pincode: z.string().optional(),
  role: z.enum(["customer", "admin", "super_admin"]).optional(),
});
export const loginSchema = z.object({
  phone: z.string().min(10),
  password: z.string().min(6),
});
export function validate(schema) {
  return (req, res, next) => {
    const r = schema.safeParse(req.body);
    if (!r.success)
      return res
        .status(422)
        .json({
          success: false,
          error: { message: "Validation failed", details: r.error.flatten() },
        });
    req.body = r.data;
    next();
  };
}
