defmodule Greenhouse.Storage do
  @moduledoc """
  Adapts ETS storage for Orchid Dehydration.

  Acts as both the Lifecycle Manager (GenServer) and the API Adapter.
  """
  use GenServer

  @table :greenhouse_blob_store

  # ===================================================================
  # Client API (Orchid Repo Contract)
  # ===================================================================

  @doc """
  Stores data and returns a reference key.

  Conforms to Orchid.Dehydration.Hook expectation: put(data, opts)
  """
  def put(data, _opts \\ []) do
    key = :erlang.phash2(data)

    try do
      :ets.insert(@table, {key, data})
      {:ok, key}
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Retrieves data by reference key.

  Conforms to Orchid.Dehydration.Hook expectation: get(key)
  """
  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, data}] -> {:ok, data}
      [] -> {:error, :not_found}
    end
  end

  # ===================================================================
  # GenServer Callbacks (Lifecycle)
  # ===================================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])

    {:ok, %{}}
  end
end
