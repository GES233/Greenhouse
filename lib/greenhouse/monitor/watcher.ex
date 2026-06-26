defmodule Greenhouse.Monitor.Watcher do
  @moduledoc """
  Watches source directories for file changes, triggers full Oi rebuild,
  then broadcasts reload via Broadcaster.
  """
  use GenServer
  require Logger

  alias Greenhouse.Monitor.Broadcaster

  @debounce_ms 500

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    source_root = Keyword.fetch!(opts, :source_root)
    compiled = Keyword.fetch!(opts, :compiled)
    data = Keyword.fetch!(opts, :data)

    # Watch _posts, img, pdf, src, _bibs
    dirs = Enum.filter(
      ["_posts", "img", "pdf", "src", "_bibs"],
      fn d -> File.exists?(Path.join(source_root, d)) end
    )

    {:ok, watcher_pid} = FileSystem.start_link(dirs: Enum.map(dirs, &Path.join(source_root, &1)))
    FileSystem.subscribe(watcher_pid)

    Logger.info("Watcher started, monitoring: #{inspect(dirs)}")

    {:ok, %{
      compiled: compiled,
      data: data,
      watcher: watcher_pid,
      timer_ref: nil
    }}
  end

  @impl true
  def handle_info({:file_event, _pid, {_path, _events}}, %{timer_ref: old_timer} = state) do
    if old_timer, do: Process.cancel_timer(old_timer)
    new_timer = Process.send_after(self(), :rebuild, @debounce_ms)
    {:noreply, %{state | timer_ref: new_timer}}
  end

  @impl true
  def handle_info({:file_event, _pid, :stop}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:rebuild, state) do
    IO.puts("\n[Watcher] Change detected, rebuilding...")

    case Oi.execute(state.compiled, data: state.data) do
      {:ok, _result} ->
        IO.puts("[Watcher] Rebuild complete.")
        Broadcaster.broadcast({:reload, %{timestamp: DateTime.utc_now() |> DateTime.to_iso8601()}})

      {:error, error} ->
        Logger.error("Rebuild failed: #{inspect(error)}")
    end

    {:noreply, %{state | timer_ref: nil}}
  end
end
