package ch.datahouse.example;

import static ch.datahouse.buildlib.myversion.MyVersion.MY_VERSION;

public class Greeter {
  // TODO: Add a test for this.
  public String greet(String name) {
    return "Hello %s from %s".format(name, MY_VERSION);
  }
}
