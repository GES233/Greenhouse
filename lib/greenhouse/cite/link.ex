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

  def convert(other), do: other
end
