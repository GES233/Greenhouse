defmodule Greenhouse.Content.PostsLoader do

  def posts_path_to_map(post_root_path, allow_ext, git_path) do
    find_posts(post_root_path, allow_ext)
    |> Task.async_stream(&parse_single_post(&1, git_path))
    |> Enum.map(fn {:ok, s} -> {s.id, s} end)
    |> Enum.into(%{})
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
