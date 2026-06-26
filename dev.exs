# Greenhouse Dev Server
# Usage: mix run dev.exs
#
# Starts a file watcher + HTTP dev server with live-reload.
# Edit any file under source/ and the browser auto-refreshes.

IO.puts("Starting Greenhouse dev server...")

# ---- Config ----
source_root = "source"
page_root_path = source_root
posts_path = Path.join(source_root, "_posts")
pic_path = Path.join(source_root, "img")
pdf_path = Path.join(source_root, "pdf")
dot_path = Path.join(source_root, "src")
bib_entry = Path.join(source_root, "_bibs")

server_port = 4000

data = %{
  load_posts: %{posts_path: posts_path},
  load_pages: %{page_root_path: page_root_path},
  load_images: %{pic_path: pic_path},
  load_pdfs: %{pdf_path: pdf_path},
  load_dots: %{dot_path: dot_path},
  markdown_posts: %{bib_entry: bib_entry},
  markdown_pages: %{bib_entry: bib_entry}
}

graph = Greenhouse.Pipeline.Graph.build()

# ---- Initial Build ----
IO.puts("Performing initial build...")

{:ok, compiled} = Oi.compile(graph)

case Oi.execute(compiled, data: data) do
  {:ok, _} -> IO.puts("Initial build complete.")
  {:error, err} ->
    IO.puts("Initial build failed: #{inspect(err)}")
    System.halt(1)
end

# ---- Start Services ----
children = [
  Greenhouse.Monitor.Broadcaster,
  {Greenhouse.Monitor.Watcher, [source_root: source_root, compiled: compiled, data: data]},
  {Plug.Cowboy, scheme: :http, plug: Greenhouse.Monitor.DevServer, options: [port: server_port]}
]

{:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)

IO.puts("""

  Greenhouse dev server running at http://localhost:#{server_port}/
  Watching #{source_root} for changes...
  Press Ctrl+C to stop.

""")

# Block forever
Process.sleep(:infinity)
