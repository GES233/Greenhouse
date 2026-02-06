defmodule Greenhouse.Params.FileDoc do
  defstruct [:id, :created_at, :updated_at, :body, :metadata]

  def from_path(path) do
    with true <- File.exists?(path),
         {:ok, %{id: id, created_at: created_at, updated_at: updated_at}, file} <-
           parse_meta(path),
         {meta, content} <- get_page_meta(file) do
      %__MODULE__{
        id: id,
        created_at: created_at,
        updated_at: updated_at,
        body: content,
        metadata: meta
      }
    else
      false ->
        {:error, :file_not_exist}
    end
  end

  defp parse_meta(path) do
    [id, _ext] = path |> Path.basename() |> String.split(".")
    {:ok, %{mtime: updated_at, ctime: created_at}} = File.stat(path)
    {:ok, %{id: id, created_at: created_at, updated_at: updated_at}, File.read!(path)}
  end

  def get_page_meta(content) do
    [header, _content_segment] =
      content
      |> :binary.split(["\n---\n", "\r\n---\r\n"])

    meta_segment =
      header
      |> :binary.split(["---\n", "---\r\n"])
      |> tl()
      |> hd()

    meta =
      cond do
        String.starts_with?(meta_segment, "%{") ->
          meta_segment
          |> Code.eval_string()
          |> case do
            {%{} = meta, _binding} -> meta
            _ -> :invalid_map
          end

        true ->
          meta_segment
          |> YamlElixir.read_from_string!(atoms: true)
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Enum.into(%{})
      end

    content_part =
      content
      |> :binary.split(["\n---\n", "\r\n---\r\n"])
      |> tl()
      |> hd()
      |> String.replace("\r\n", "\n")

    {meta, content_part}
  end
end
