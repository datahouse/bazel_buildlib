import myVersion from "./myVersion.js";

export function myLibraryFunction(x: number, y: number) {
  return x + y;
}

export function appInfo() {
  return `it-bazel example ${myVersion}`;
}
