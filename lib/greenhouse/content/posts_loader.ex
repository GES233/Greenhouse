defmodule Greenhouse.Content.PostsLoader do
  @moduledoc """
  Load content into orchid's params.
  """
  use Orchid.Step
  import Orchid.Steps.Helpers

  @opts_schema [
    ignore_markdown: [
      type: :boolean,
      default: true,
      doc: "Ignore *.markdown files"
    ],
    use_git: [
      type: :boolean,
      default: false,
      doc: "Use git commit time as updated date"
    ],
    git_repo: [
      type: :string,
      required: false,
      doc: "Path to git repository (optional)"
    ]
  ]

  @doc """
  ## Options

  * `:ignore_markdown` (Boolean) - Ignore `*.markdown`, default as true.
  * `:use_git` (Boolean) - If true, return updated date by git commit.
  * `:git_repo` (Optional(Binary))
  """
  def validate_options(step_options) do
    NimbleOptions.validate(drop_orchid_native(step_options), @opts_schema)
  end

  def run(%Orchid.Param{payload: post_root_path}, step_options) do
    opts =
      step_options
      |> drop_orchid_native()
      |> NimbleOptions.validate!(@opts_schema)

    git_path =
      if opts[:use_git] do
        opts[:git_repo] || Path.dirname(post_root_path)
      else
        nil
      end

    allow_ext =
      if opts[:ignore_markdown],
        do: ["md"],
        else: ~w(md markdown)

    {:ok,
     find_posts(post_root_path, allow_ext)
     |> Task.async_stream(&parse_single_post(&1, git_path))
     |> Enum.map(fn {:ok, s} -> {s.id, s} end)
     |> Enum.into(%{})
     |> then(&Orchid.Param.new(:posts_map, :map, &1))}
  end

  defp find_posts(root, exts) do
    Enum.flat_map(exts, fn ext ->
      Path.wildcard(Path.join(root, "**/*.#{ext}"))
    end)
  end

  defp parse_single_post(path, root) do
    path
    |> Greenhouse.Content.FileDoc.from_path()
    |> Greenhouse.Content.Post.from_file_doc(root, Path.extname(path))
  end
end
