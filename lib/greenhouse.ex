defmodule Greenhouse do
  @moduledoc """
  Documentation for `Greenhouse`.
  """

  @doc "A helper to inspect result."
  def inspector(steps, init_params) do
    Orchid.run(steps, init_params)
    |> case do
      {:ok, result} -> Enum.map(result, fn {k, %Orchid.Param{payload: v}} -> {k, v} end)
      {:error, %Orchid.Error{reason: reason}} -> raise reason
    end
  end

  @doc """
  Hello world.

  ## Examples

      iex> Greenhouse.hello()
      :world

  """
  def hello do
    :world
  end
end
