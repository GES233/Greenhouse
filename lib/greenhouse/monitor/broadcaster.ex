defmodule Greenhouse.Monitor.Broadcaster do
  @moduledoc """
  Simple PubSub for SSE live-reload notifications.
  Subscribers receive `{:reload, data}` messages.
  """
  use GenServer

  # ---- Public API ----

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  end

  def subscribe do
    GenServer.call(__MODULE__, {:subscribe, self()})
  end

  def broadcast(message) do
    GenServer.cast(__MODULE__, {:broadcast, message})
  end

  # ---- Callbacks ----

  @impl true
  def init(subscribers) do
    {:ok, subscribers}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, subscribers) do
    Process.monitor(pid)
    {:reply, :ok, MapSet.put(subscribers, pid)}
  end

  @impl true
  def handle_cast({:broadcast, message}, subscribers) do
    Enum.each(subscribers, fn pid -> send(pid, message) end)
    {:noreply, subscribers}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, subscribers) do
    {:noreply, MapSet.delete(subscribers, pid)}
  end
end
