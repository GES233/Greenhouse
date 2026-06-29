
source_root = "source"
data = %{
  load_posts: %{posts_path: Path.join(source_root, "_posts")},
  load_pages: %{page_root_path: source_root},
  load_images: %{pic_path: Path.join(source_root, "img")},
  load_pdfs: %{pdf_path: Path.join(source_root, "pdf")},
  load_dots: %{dot_path: Path.join(source_root, "src")},
  markdown_posts: %{bib_entry: Path.join(source_root, "_bibs")},
  markdown_pages: %{bib_entry: Path.join(source_root, "_bibs")}
}

graph = Greenhouse.Pipeline.Graph.build()
{:ok, compiled} = Oi.compile(graph)

{_, agent} = Agent.start_link(fn -> %{start: %{}, durations: []} end)

:telemetry.attach("t-start", [:orchid, :step, :start],
  fn _, _, meta, _ -> Agent.update(agent, &put_in(&1.start[meta.impl], System.monotonic_time())) end, nil)
:telemetry.attach("t-done", [:orchid, :step, :done],
  fn _, _, meta, _ -> Agent.update(agent, fn s ->
    dur = System.monotonic_time() - s.start[meta.impl]
    %{s | durations: [{meta.impl, dur} | s.durations]}
  end) end, nil)

Oi.execute(compiled, data: data,
  orchid_opts: [global_hooks_stack: [Orchid.Runner.Hooks.Telemetry]])

durs = Agent.get(agent, & &1.durations) |> Enum.reverse()
total = durs |> Enum.map(&elem(&1,1)) |> Enum.sum()

IO.puts("\n=== Step Durations ===")
Enum.each(durs, fn {mod, dur} ->
  ms = System.convert_time_unit(dur, :native, :millisecond)
  IO.puts("  #{String.pad_trailing(inspect(mod), 50)} #{String.pad_leading("#{ms}", 5)} ms")
end)
IO.puts("  #{String.duplicate("-", 65)}")
IO.puts("  #{String.pad_trailing("TOTAL", 50)} #{String.pad_leading("#{System.convert_time_unit(total, :native, :millisecond)}", 5)} ms")

Agent.stop(agent)
