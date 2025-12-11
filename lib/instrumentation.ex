defmodule Instrumentation do
  defmacro __using__(definitions) do
    quote do
      Module.register_attribute(__MODULE__, :to_instrument, accumulate: true)
      @definitions unquote(definitions)
      @before_compile unquote(__MODULE__)
      @on_definition unquote(__MODULE__)

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
    to_instrument = Module.get_attribute(module, :to_instrument)
    definitions = normalize(module, definitions ++ to_instrument)
    Module.make_overridable(module, strip_tags(definitions))

    Enum.map(definitions, fn {name, arity, tag} ->
      args = build_args(arity)

      quote do
        def unquote(name)(unquote_splicing(args)) do
          IO.inspect("instrumented", label: unquote(tag))
          super(unquote_splicing(args))
        end
      end
    end)
  end

  def __on_definition__(env, kind, name, args, _guards, _body) when kind in [:def, :defp] do
    {set, _bag} = :elixir_module.data_tables(env.module)

    case :ets.take(set, :pokemon) do
      [{:pokemon, pokemon, _anno, _meta}] ->
        arity = length(args)
        Module.put_attribute(env.module, :to_instrument, {name, arity, pokemon})

      [] ->
        :ok
    end
  end

  def __on_definition__(_env, _kind, _name, _args, _guards, _body), do: :ok

  defp normalize(module, definitions) do
    Enum.map(definitions, fn
      {name, arity} -> {name, arity, build_tag(module, name)}
      {name, arity, tag} -> {name, arity, tag}
    end)
  end

  defp strip_tags(definitions) do
    Enum.map(definitions, fn
      {name, arity} -> {name, arity}
      {name, arity, _tag} -> {name, arity}
    end)
  end

  defp build_tag(module, name) do
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
