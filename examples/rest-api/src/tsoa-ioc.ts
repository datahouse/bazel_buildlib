/**
 * This file is the IoC module that `tsoa` will call when creating the controllers (also check the `tsoa.json` file).
 * By default all the controllers are created by the auto-generated routes template using an empty default constructor.
 * However, since we want to have constructor parameters, the generated code needs to inject them
 * (because it generates the instantiation of the classes).
 * We need contructor parameters to improve the Prisma connection management (single Prisma client instance for the entire application).
 *
 * In general, this is not a pattern we want to use, we just do it for `tsoa`.
 */

import { Request, Application } from "express";

import { IocContainer, IocContainerFactory } from "@tsoa/runtime";

import ServerContext from "./ServerContext.js";

class IocContainerAdapter implements IocContainer {
  constructor(private ctx: ServerContext) {}

  public get<T>(controller: { prototype: T }): T {
    const constructor = controller as new (ctx: ServerContext) => T;
    return new constructor(this.ctx);
  }
}

export type ContextFactory = (req: Request) => ServerContext;

const registeredFactories = new WeakMap<Application, ContextFactory>();

export const iocContainer: IocContainerFactory = (req: Request) => {
  const factory = registeredFactories.get(req.app);

  if (factory === undefined) {
    throw new Error(
      `Couldn't find a context factory for {app}. Did you call RegisterServerContext?`,
    );
  }

  return new IocContainerAdapter(factory(req));
};

export function RegisterServerContext(
  app: Application,
  factory: ContextFactory,
): void {
  if (registeredFactories.has(app)) {
    throw new Error(`already have a factory for {app}`);
  }

  registeredFactories.set(app, factory);
}
