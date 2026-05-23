defmodule Greenhouse.Monitor.DevServer do
  @moduledoc """
  Plug pipeline for dev server: SSE endpoint + static file serving.
  SSE live-reload script is injected at build time via scaffold.html.eex.
  """
  use Plug.Builder

  plug :sse_handler
  plug :redirect_index
  plug Plug.Static,
    at: "/",
    from: "exports",
    only: ~w(css js dist image svg archive pdf assets),
    gzip: false
  plug :serve_html
  plug :not_found

  # /sse endpoint for live-reload EventSource
  defp sse_handler(%Plug.Conn{path_info: ["sse"]} = conn, _opts) do
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> send_chunked(200)
    |> sse_loop()
    |> halt()
  end

  defp sse_handler(conn, _opts), do: conn

  defp sse_loop(conn) do
    Greenhouse.Monitor.Broadcaster.subscribe()

    receive do
      {:reload, data} ->
        chunk = "event: reload\ndata: #{Map.get(data, :timestamp)}\n\n"

        case Plug.Conn.chunk(conn, chunk) do
          {:ok, conn} -> sse_loop(conn)
          {:error, :closed} -> conn
        end
    after
      25_000 ->
        case Plug.Conn.chunk(conn, ": keepalive\n\n") do
          {:ok, conn} -> sse_loop(conn)
          {:error, :closed} -> conn
        end
    end
  end

  # Append index.html for clean URLs like /about, /2025/10/Post
  defp redirect_index(%Plug.Conn{path_info: path} = conn, _opts) do
    # If path has no file extension, treat as directory -> index.html
    last = List.last(path, "")
    if String.contains?(last, ".") do
      conn
    else
      %{conn | path_info: path ++ ["index.html"]}
    end
  end

  # Serve HTML files from exports/ with proper content type
  defp serve_html(%Plug.Conn{path_info: path} = conn, _opts) do
    file_path = Path.join(["exports" | path])
    if File.exists?(file_path) do
      conn
      |> put_resp_content_type("text/html; charset=utf-8")
      |> send_resp(200, File.read!(file_path))
      |> halt()
    else
      conn
    end
  end

  defp not_found(conn, _opts) do
    send_resp(conn, 404, "Not found")
  end
end
