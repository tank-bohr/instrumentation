defmodule Instrumentation.Over do
  def foo(x) do
    x
  end

  defoverridable foo: 1

  def foo(x) do
    super(x) + 1
  end
end
