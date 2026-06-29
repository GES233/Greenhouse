defmodule Greenhouse.Pipeline.Telemetry do
  @moduledoc """
  Lightweight telemetry harness for Oi/Orchid step profiling.

  Returns `{orchid_opts, cleanup_fn}` — merge `orchid_opts` into your
  `Oi.execute/2` call and invoke `cleanup_fn.()` after for a duration report.

  ## Example

      {extra, report} = Greenhouse.Pipeline.Telemetry.setup()

      Oi.execute(compiled, data: data, Keyword.merge(extra, []))

      report.()
  """

  @doc """
  Starts telemetry capture and returns `{orchid_opts, report_fn}`.

  `orchid_opts` must be merged into `Oi.execute/2` opts.
  `report_fn/0` prints a duration table and cleans up.
  """
  @spec setup() :: {keyword(), (-> :ok)}
  def setup do
    {:ok, agent} = Agent.start_link(fn -> %{start: %{}, durations: []} end)

    :telemetry.attach(
      "gh-tel-start",
      [:orchid, :step, :start],
      fn _, _, meta, _ ->
        Agent.update(agent, &put_in(&1.start[meta.impl], System.monotonic_time()))
      end,
      nil
    )

    :telemetry.attach(
      "gh-tel-done",
      [:orchid, :step, :done],
      fn _, _, meta, _ ->
        Agent.update(agent, fn state ->
          dur = System.monotonic_time() - state.start[meta.impl]
          %{state | durations: [{meta.impl, dur} | state.durations]}
        end)
      end,
      nil
    )

    orchid_opts = [global_hooks_stack: [Orchid.Runner.Hooks.Telemetry]]

    {orchid_opts, fn -> print_report(agent) end}
  end

  defp print_report(agent) do
    durations =
      agent
      |> Agent.get(& &1.durations)
      |> Enum.reverse()

    total =
      durations
      |> Enum.map(&elem(&1, 1))
      |> Enum.sum()

    total_ms = System.convert_time_unit(total, :native, :millisecond)

    IO.puts("")
    IO.puts("=== Step Durations (#{total_ms} ms total) ===")

    durations
    |> Enum.each(fn {mod, dur} ->
      ms = System.convert_time_unit(dur, :native, :millisecond)
      bar = String.duplicate("▊", min(trunc(ms / 50), 40))
      IO.puts("  #{String.pad_trailing(inspect(mod), 50)} #{String.pad_leading("#{ms}", 5)} ms  #{bar}")
    end)

    Agent.stop(agent)
    :telemetry.detach("gh-tel-start")
    :telemetry.detach("gh-tel-done")
  end
end
