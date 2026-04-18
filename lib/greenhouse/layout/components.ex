defmodule Greenhouse.Layout.Components do
  alias Greenhouse.Content.{Post, Page}

  ## Title

  ## Meta

  def get_options(%Post{extra: raw_option}) do
    extract_pandoc_options(raw_option)
  end

  def get_options(%Page{extra: raw_option}) do
    extract_pandoc_options(raw_option)
  end

  defp extract_pandoc_options(raw_option) when is_map(raw_option) do
    {_, option} = Map.pop(raw_option, "pandoc")
    option
  end

  defp extract_pandoc_options(_), do: nil
end
