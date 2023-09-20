import myVersion from "./myVersion";

export function myLibraryFunction(x: number, y: number) {
  return x + y;
}

export function greeting() {
  return `Hello from ${myVersion}`;
}
