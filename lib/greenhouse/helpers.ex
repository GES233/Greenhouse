defmodule Greenhouse.Helpers do
end

defmodule Greenhouse.Helpers.PathUtils do
  @moduledoc """
  Provides utility functions for handling file paths.
  """

  @doc """
  Converts a file path into a canonical, normalized format.
  - Makes the path absolute.
  - Converts all separators to forward slashes (`/`).
  - Downcases the drive letter on Windows.
  """
  def normalize(path) do
    normalized = path |> Path.expand()

    if :os.type() == {:win32, :nt} do
      Regex.replace(~r/^[A-Z]:/, String.replace(normalized, "\\", "/"), &String.downcase/1)
    else
      normalized
    end
  end
end

# From
# https://www.thegreatcodeadventure.com/elixir-tricks-building-a-recursive-function-to-list-all-files-in-a-directory/
defmodule Greenhouse.Helpers.FlatFiles do
  def list_all(filepath) do
    do_list_all(filepath)
  end

  defp do_list_all(filepath) do
    cond do
      String.contains?(filepath, ".git") -> []
      true -> expand(File.ls(filepath), filepath)
    end
  end

  defp expand({:ok, files}, path) do
    files
    |> Enum.flat_map(&do_list_all("#{path}/#{&1}"))
  end

  defp expand({:error, _}, path) do
    [path]
  end
end
