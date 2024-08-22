import express, { Application } from "express";

import { RegisterRoutes } from "./routes.js";

import { ContextFactory, RegisterServerContext } from "./tsoa-ioc.js";

export const setupApp = (context: ContextFactory): Application => {
  const app = express();

  const router = express.Router();

  RegisterServerContext(app, context);

  RegisterRoutes(router);

  app.use(express.json());
  app.use("/", router);

  return app;
};
