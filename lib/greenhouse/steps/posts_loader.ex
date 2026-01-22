defmodule Greenhouse.Steps.PostsLoader do
  @moduledoc """
  Load content into orchid's params.
  """
  use Orchid.Step

  def as_declarative(opts \\ []), do: {__MODULE__, :posts_path, :posts_map, opts}

  @doc """
  ## Options

  * `:ignore_markdown` (Boolean) - Ignore `*.markdown`, default as true.
  * `:use_git`
  """
  def validate_options(_step_options) do
    :ok
  end

  def run(%Orchid.Param{payload: post_root_path}, _step_options) do
    git_path = Path.dirname(post_root_path)

    {:ok,
     Path.wildcard(post_root_path <> "/**/*.md")
     |> Task.async_stream(&parse_single_post(&1, git_path))
     |> Enum.map(fn {:ok, s} -> {s.id, s} end)
     |> Enum.into(%{})
     |> then(&Orchid.Param.new(:posts_map, Map, &1))}
  end

  defp parse_single_post(path, root) do
    path
    |> Greenhouse.Params.FileDoc.from_path()
    |> Greenhouse.Params.Post.from_file_doc(root)
  end
end
