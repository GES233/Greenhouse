defmodule Greenhouse.Cite.Link do
  alias Greenhouse.Content.{Post, Page}
  alias Greenhouse.Asset.Media

  @root "/"

  def convert(%Post{} = post) do
    "#{@root}#{post.created_at.year}/#{post.created_at.month}/#{post.id}"
  end

  def convert(%Page{} = page) do
    case page.route do
      nil -> "#{@root}#{page.id}"
      _ -> "#{@root}#{page.route}"
    end
  end

  def convert(%Media{} = media) do
    route = media.route_path

    case route do
      route when is_binary(route) -> "#{@root}#{route}"
      # When filaed => inject raw file(some compile scene)
      nil -> ""
    end
  end

  def convert({:tag, tag_name}) do
    name = sanitize_name(tag_name)
    "#{@root}tags/#{name}"
  end

  def convert({:category, cat_name}) do
    name = sanitize_name(cat_name)
    "#{@root}categories/#{name}"
  end

  def convert({:series, series_name}) do
    name = sanitize_name(series_name)
    "#{@root}series/#{name}"
  end

  def convert(other), do: other

  defp sanitize_name(name) when is_list(name), do: Enum.join(name, "-") |> sanitize_string()
  defp sanitize_name(name), do: to_string(name) |> sanitize_string()
  
  # Allow chinese characters
  defp sanitize_string(str) do
    # Only replace spaces and actual special characters, keep unicode (like Chinese)
    str
    |> String.replace(~r/[ \.\/\\]+/, "-")
  end
end
