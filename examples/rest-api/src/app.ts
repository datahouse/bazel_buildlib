import express, { Application, ErrorRequestHandler } from "express";
import swaggerUi from "swagger-ui-express";
import { ValidateError } from "tsoa";

import swaggerDocument from "./swagger.json";
import { RegisterRoutes } from "./routes";

import { ContextFactory, RegisterServerContext } from "./tsoa-ioc";

export interface Console {
  error(msg: string, ...params: unknown[]): void;
}

const errorHandler =
  (console: Console): ErrorRequestHandler =>
  // We must define next for express to interpret this as ErrorRequestHandler
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  (err: unknown, req, res, next) => {
    if (err instanceof ValidateError) {
      console.error(`ValidationError for ${req.path}:`, err.fields);
      res.status(422).json({
        message: "Validation Failed",
        details: err?.fields,
      });
    } else {
      console.error(`Internal Error for ${req.path}:`, err);
      res.status(500).json({
        message: "Internal Server Error",
      });
    }
  };

export const setupApp = (
  console: Console,
  context: ContextFactory,
): Application => {
  const app = express();

  const router = express.Router();

  RegisterServerContext(app, context);

  RegisterRoutes(router);
  router.use("/spec/", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

  // Setup the app at the actual visible serving path.
  // Otherwise SwaggerUI will not perform correct redirects.

  app.use(express.json());
  app.use("/api/v1", router);

  app.use(errorHandler(console));

  return app;
};
