import { mock } from "jest-mock-extended";

interface FooProvider {
  foo(i: number): void;
}

test("allow to expect on MockProxy (no unbound-method lint error) - #475", () => {
  const fooProvider = mock<FooProvider>();

  fooProvider.foo(1);

  // The use of `foo` here is unbound but OK.
  expect(fooProvider.foo).toHaveBeenCalledWith(1);
});
