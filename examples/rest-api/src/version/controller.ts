import { Controller, Get, Route } from "tsoa";

import myVersion from "./myVersion.js";

@Route("version")
export class VersionController extends Controller {
  /** Returns the build version of the server. */
  @Get()
  public version(): string {
    return myVersion;
  }
}
