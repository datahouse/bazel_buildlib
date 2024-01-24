import "reflect-metadata";

import { Arg, Ctx, Mutation, Resolver, Int } from "type-graphql";

import GraphQLUpload from "graphql-upload-cjs/GraphQLUpload";
import { FileUpload } from "graphql-upload-cjs/Upload";

import Context from "../Context.js";

/** Resolver to add and delete attachments.
 *
 *  This is a custom resolver so it can maintain consistency with the BlobStore.
 *  We ensure that no CRUD can be performed via RLS.
 *
 *  A note about the return types: Ideally we'd return a TodoAttachment from
 *  both resolvers. However, this would require us to properly configure field
 *  resolvers for the item field. Since we do not need the better return values
 *  in the FE, we don't bother.
 *
 *  The return types are a future point of improvement to have an example for
 *  projects that need this.
 */
@Resolver()
export default class AttachmentResolver {
  @Mutation(() => Int, { nullable: false })
  uploadTodoAttachment(
    @Arg("itemId", () => Int) itemId: number,
    @Arg("file", () => GraphQLUpload) file: FileUpload,
    @Ctx() ctx: Context,
  ): Promise<number> {
    // Execute in a transaction: If downloading / storing the file
    // fails, we do not want to add the row.
    return ctx.elevatedPrisma.$transaction(async (tx) => {
      // Note: FileUpload also offers `encoding`:
      // However, this is the transfer encoding (the encoding on the wire). We
      // do not care about it: Once we have the file, it's irrelevant how we got it.
      const { filename, mimetype } = file;

      const { uuid, id } = await tx.todoAttachment.create({
        data: { itemId, filename, mimetype },
        select: { id: true, uuid: true },
      });

      await ctx.blobStore.put(uuid, file.createReadStream());

      return id;
    });
  }

  @Mutation(() => Int, { nullable: false })
  async deleteAttachment(
    @Arg("id", () => Int) id: number,
    @Ctx() ctx: Context,
  ): Promise<number> {
    // Delete the attachment metadata first, only then delete the file.
    // In the worst case, this leaves a dangling file in the blob store, but
    // that's better than having the metadata but not the file anymore.
    const { uuid } = await ctx.elevatedPrisma.todoAttachment.delete({
      where: { id },
    });

    await ctx.blobStore.del(uuid);

    return id;
  }
}
