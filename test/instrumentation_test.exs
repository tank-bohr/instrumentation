defmodule InstrumentationTest do
  use ExUnit.Case
  doctest Instrumentation

  test "greets the world" do
    assert Instrumentation.hello() == :world
  end
end
