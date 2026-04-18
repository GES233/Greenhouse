defmodule Greenhouse.Theme do
  @moduledoc """
  The behaviour that all Greenhouse themes must implement.
  By implementing this behaviour, you can create a pluggable theme for the blog engine.
  """

  alias Greenhouse.Content.{Post, Page}

  @doc """
  Render a single blog post.
  Returns a `{path, html_content}` tuple or just `html_content` depending on pipeline needs.
  """
  @callback render_post(post :: Post.t(), global_assigns :: map()) :: binary()

  @doc """
  Render a single standalone page (e.g. About, Friends).
  """
  @callback render_page(page :: Page.t(), global_assigns :: map()) :: binary()

  @doc """
  Render the index page containing a list of posts.
  """
  @callback render_index(posts :: [Post.t()], global_assigns :: map()) :: binary()

  @doc """
  Render taxonomy pages (tags, categories, series).
  `type` would be `:tag`, `:category`, or `:series`.
  `items` is the list of items under that taxonomy.
  """
  @callback render_taxonomy(
              type :: atom(),
              name :: String.t(),
              items :: list(),
              global_assigns :: map()
            ) :: binary()
end
