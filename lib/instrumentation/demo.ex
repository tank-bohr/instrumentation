defmodule Instrumentation.Demo do
  # use Instrumentation, [hello: 0]

  def hello(name \\ :world) do
    "hello #{name}"
  end
end
