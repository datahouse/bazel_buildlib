import { Controller, Get, Route, Path } from "tsoa";

import type ServerContext from "./ServerContext.js";
import { PrismaDelegate } from "./prisma.js";

@Route("/")
export class BlobAuthController extends Controller {
  public constructor(private readonly serverCtx: ServerContext) {
    super();
  }

  private async authCheck(
    prismaDelegate: PrismaDelegate,
    uuid: string,
  ): Promise<void> {
    const blobInfo = await prismaDelegate.findUnique({
      where: { uuid },
      select: { filename: true, mimetype: true },
    });

    if (blobInfo === null) {
      this.setStatus(403);
      return;
    }

    const { mimetype, filename } = blobInfo;

    this.setHeader("Content-Type", mimetype);

    const encodedFilename = encodeURIComponent(filename);

    // See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition
    this.setHeader(
      "Content-Disposition",
      `inline; filename*=UTF-8''${encodedFilename}`,
    );
  }

  // Attention: The string "todoAttachment" here is unvalidated user input.
  // When modifying this, be careful not to use it to select a property / field on an object.
  // Otherwise this leaves a big security hole (users can select arbitrary JS properties).
  //
  // The example gets around this by simply duplicating the string and not
  // dynamically selecting on any object. Since we can abstract pretty much all
  // logic into the `authCheck` helper, this is very minimal overhead, but very
  // safe / secure.
  @Get("/todoAttachment/{uuid}")
  public checkTodoAttachment(@Path() uuid: string): Promise<void> {
    return this.authCheck(this.serverCtx.prisma.todoAttachment, uuid);
  }
}
