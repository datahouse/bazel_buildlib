import { Controller, Get, Post, Route, Path, Body } from "tsoa";

import { TodoList, TodoItem } from "../../../prisma/prisma-client";

import ServerContext from "../ServerContext";

@Route("todo-lists")
export class TodoListsController extends Controller {
  public constructor(private readonly serverCtx: ServerContext) {
    super();
  }

  /** Returns all Todo Lists. */
  @Get("/")
  public getLists(): Promise<TodoList[]> {
    return this.serverCtx.prisma.todoList.findMany();
  }

  /** Returns a Todo List. */
  @Get("/{listId}")
  public getList(@Path() listId: number): Promise<TodoList> {
    return this.serverCtx.prisma.todoList.findUniqueOrThrow({
      where: { id: listId },
    });
  }

  /** Returns all Todo Items for a list. */
  @Get("/{listId}/items")
  public getItems(@Path() listId: number): Promise<TodoItem[]> {
    return this.serverCtx.prisma.todoItem.findMany({
      where: { listId },
    });
  }

  /** Create a new Todo Item. */
  @Post("/{listId}/items")
  public createItem(
    @Path() listId: number,
    // Pick fields we allow.
    @Body() item: Pick<TodoItem, "text" | "done">,
  ): Promise<TodoItem> {
    return this.serverCtx.prisma.todoItem.create({
      data: {
        listId,
        ...item,
      },
    });
  }
}
