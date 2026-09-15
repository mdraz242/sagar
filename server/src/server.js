import dotenv from "dotenv";
dotenv.config();

import http from "http";
import { app } from "./app.js";
import { initRealtime } from "./services/realtimeService.js";

const port = process.env.PORT || 8080;
const server = http.createServer(app);

initRealtime(server, process.env.CORS_ORIGIN || "*");

server.listen(port, () => console.log(`VyparHub API listening on ${port}`));
