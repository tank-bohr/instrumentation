defmodule Instrumentation do
  defmacro __using__(definitions) do
    quote do
      @definitions unquote(definitions)
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__), only: [instrument: 2]

      def to_erl do
        beam_path = :code.wich(unquote(__MODULE__))
        {:ok, beam} = File.read(beam_path)
        {:ok, {mode, chunks}} = :beam_lib.chunks(beam, [:abstract_code])
        {_, abstract_code} = chunks[:abstract_code]
        content = :erl_prettypr.format(:erl_syntax.form_list(abstract_code))
        File.write("erlang_source.erl", content)
      end
    end
  end

  defmacro __before_compile__(env) do
    definitions = Module.get_attribute(env.module, :definitions)
    {set, bag} = :elixir_module.data_tables(env.module)
    Enum.each(definitions, fn definition ->
      [original] = :ets.lookup(set, {:def, definition})
      clauses = :ets.lookup(bag, {:clauses, definition})
      :ets.delete(bag, {:clauses, definition})
      :ets.insert(bag, rename_clauses(clauses))
      :ets.insert(bag, instrumented_clause(env.module, definition))
      :ets.insert(set, rename(original))
    end)

    {:__block__, [], []}
  end

  def instrument(func, tag) do
    IO.inspect(func.(), label: tag)
  end

  defp instrumented_clause(module, {name, arity} = definition) do
    name = rename(name)
    args = build_args(arity)
    tag = build_tag(module, definition)
    body = {:instrument, [], [{:fn, [], [{:->, [], [[], {name, [], args}]}]},
    tag]}
    {{:clauses, definition}, {[], args, [], body}}
  end

  defp rename(name) when is_atom(name) do
    String.to_atom("#{name}_without_instrumentation")
  end

  defp rename(tuple) when is_tuple(tuple) do
    tuple
    |> update_in([Access.elem(0), Access.elem(0)], &rename/1)
    |> update_in([Access.elem(1)], fn _kind -> :defp end)
  end

  defp rename_clauses(clauses) do
    Enum.map(clauses, &rename_clause/1)
  end

  defp rename_clause({{:clauses, {name, arity}}, value}) do
    {{:clauses, {rename(name), arity}}, value}
  end

  defp build_tag(module, {name, _arity}) do
    module
    |> to_string()
    |> String.downcase()
    |> then(fn mod -> "#{mod}_#{name}" end)
  end

  defp build_args(arity) do
    1..255
    |> Stream.map(fn idx -> {String.to_atom("a#{idx}"), [], nil} end)
    |> Enum.take(arity)
  end
end
