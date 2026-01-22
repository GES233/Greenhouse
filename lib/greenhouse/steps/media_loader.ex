defmodule Greenhouse.Steps.MediaLoader do
  use Orchid.Step

  def as_declarative(opts \\ []), do: {__MODULE__, :media_path, [:media_map], opts}

  def run(%Orchid.Param{payload: _media_path}, _step_options) do
    {:ok, Orchid.Param.new(:name, :type, :value)}
  end
end
