defmodule Instrumentation.Demo do
  use Instrumentation, hello: 1

  def hello(name) do
    "hello #{name}"
  end

  @pokemon "pikachu"
  def annotated do
    :ok
  end
end
