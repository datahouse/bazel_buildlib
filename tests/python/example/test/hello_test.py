from example.src import hello


# Dependency smoke test: fail CI if a bump breaks pytest
def test_say_hello_returns_expected():
    assert hello.say_hello("Canary") == "Hello, Canary!"
