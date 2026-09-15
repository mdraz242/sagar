import jwt from "jsonwebtoken";
import { Server } from "socket.io";

let io;
let adminNamespace;
let customerNamespace;

const adminAccessSecret = () =>
  process.env.ADMIN_JWT_ACCESS_SECRET ||
  `${process.env.JWT_ACCESS_SECRET}-admin`;
const customerAccessSecret = () => process.env.JWT_ACCESS_SECRET;
const adminAudience = "vyparhub-admin";

function tokenFromSocket(socket) {
  const authToken = socket.handshake.auth?.token;
  const header = socket.handshake.headers?.authorization || "";
  if (authToken) return authToken;
  if (header.startsWith("Bearer ")) return header.slice(7);
  return null;
}

function reject(message) {
  const error = new Error(message);
  error.data = { message };
  return error;
}

export function initRealtime(server, corsOrigin = "*") {
  io = new Server(server, {
    cors: {
      origin: corsOrigin,
      credentials: true,
    },
  });

  adminNamespace = io.of("/admin");
  customerNamespace = io.of("/customer");

  adminNamespace.use((socket, next) => {
    try {
      const token = tokenFromSocket(socket);
      if (!token) return next(reject("Missing admin token"));
      const payload = jwt.verify(token, adminAccessSecret(), {
        audience: adminAudience,
      });
      if (payload.scope !== "admin") return next(reject("Invalid admin scope"));
      socket.data.admin = payload;
      socket.join("admins");
      next();
    } catch {
      next(reject("Invalid admin token"));
    }
  });

  customerNamespace.use((socket, next) => {
    try {
      const token = tokenFromSocket(socket);
      if (!token) return next(reject("Missing customer token"));
      const payload = jwt.verify(token, customerAccessSecret());
      socket.data.user = payload;
      socket.join(`customer:${payload.sub}`);
      next();
    } catch {
      next(reject("Invalid customer token"));
    }
  });

  return io;
}

export function emitAdmin(event, payload = {}) {
  adminNamespace?.to("admins").emit(event, payload);
}

export function emitCustomer(userId, event, payload = {}) {
  if (!userId) return;
  customerNamespace?.to(`customer:${userId}`).emit(event, payload);
}

export function emitCustomers(event, payload = {}) {
  customerNamespace?.emit(event, payload);
}

export function realtimeReady() {
  return Boolean(io);
}
