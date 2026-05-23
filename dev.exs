# Greenhouse Dev Server
# Usage: mix run dev.exs
#
# Starts a file watcher + HTTP dev server with live-reload.
# Edit any file under source/ and the browser auto-refreshes.

IO.puts("Starting Greenhouse dev server...")

# ---- Config ----
source_root = "D:/Blog/source"
page_root_path = source_root
posts_path = Path.join(source_root, "_posts")
pic_path = Path.join(source_root, "img")
pdf_path = Path.join(source_root, "pdf")
dot_path = Path.join(source_root, "src")
bib_entry = Path.join(source_root, "_bibs")

server_port = 4000

import Orchid.ParamFactory

params = [
  to_param(page_root_path, :path),
  to_param(posts_path, :path),
  to_param(pic_path, :path),
  to_param(pdf_path, :path),
  to_param(dot_path, :path),
  to_param(bib_entry, :path)
]

recipe = Greenhouse.Pipeline.Recipe.build()

# ---- Initial Build ----
IO.puts("Performing initial build...")
case Orchid.run(recipe, params) do
  {:ok, _} -> IO.puts("Initial build complete.")
  {:error, err} ->
    IO.puts("Initial build failed: #{inspect(err)}")
    System.halt(1)
end

# ---- Start Services ----
children = [
  Greenhouse.Monitor.Broadcaster,
  {Greenhouse.Monitor.Watcher, [source_root: source_root, recipe: recipe, params: params]},
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
