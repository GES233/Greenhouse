defmodule Greenhouse.Steps.PagesLoader do
  use Orchid.Step

  def as_declarative(opts \\ []), do: {__MODULE__, :page_path_list, :pages_map, opts}

  def run(%Orchid.Param{payload: _list, metadata: %{root_path: _root_path}}, _opts) do
    {:ok, Orchid.Param.new(:any, :bla)}
  end
end
