defmodule Instrumentation do
  defmacro __using__(definitions) do
    quote do
      @definitions unquote(definitions)
      @before_compile unquote(__MODULE__)

      def to_erl do
        beam_path = :code.which(__MODULE__)
        {:ok, beam} = File.read(beam_path)
        {:ok, {mode, chunks}} = :beam_lib.chunks(beam, [:abstract_code])
        {_, abstract_code} = chunks[:abstract_code]
        content = :erl_prettypr.format(:erl_syntax.form_list(abstract_code))
        File.write("erlang_source.erl", content)
      end
    end
  end

  defmacro __before_compile__(env) do
    module = env.module
    definitions = Module.get_attribute(module, :definitions)
    Module.make_overridable(module, definitions)

    Enum.map(definitions, fn {name, arity} = definition ->
      tag = build_tag(module, definition)
      args = build_args(arity)
      quote do
        def unquote(name)(unquote_splicing(args)) do
          IO.inspect("instrumented", label: unquote(tag))
          super(unquote_splicing(args))
        end
      end
    end)
  end

  defp build_tag(module, {name, _arity}) do
    module
    |> Module.split()
    |> Enum.drop(1)
    |> Enum.join("_")
    |> String.downcase()
    |> then(fn mod -> "#{mod}_#{name}" end)
  end

  defp build_args(arity) do
    1..255
    |> Stream.map(fn idx -> {String.to_atom("a#{idx}"), [], nil} end)
    |> Enum.take(arity)
  end
end
