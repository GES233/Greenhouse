defmodule Greenhouse.Params.Link do
  alias Greenhouse.Params.{Post, Page}

  @root "/"

  def convert(%Post{} = post) do
    "#{@root}#{post.created_at.year}/#{post.created_at.month}/#{post.id}"
  end

  def convert(%Page{} = page) do
    "#{@root}#{page.id}"
  end
end
