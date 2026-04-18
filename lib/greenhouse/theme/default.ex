defmodule Greenhouse.Theme.Default do
  @moduledoc """
  The default built-in EEx-based theme for Greenhouse.
  """
  @behaviour Greenhouse.Theme

  alias Greenhouse.Content.{Post, Page}
  alias Greenhouse.Layout.View

  @impl true
  def render_post(%Post{} = post, assigns) do
    # You can merge global assigns with post-specific ones
    page_assigns =
      assigns
      |> Map.put(:page_title, post.title)
      |> Map.put(:meta, render_meta(post))
      |> Map.put(:inner_content, render_post_content(post))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_page(%Page{} = page, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, page.title || "Page")
      # Add any page-specific meta
      |> Map.put(:meta, "")
      |> Map.put(:inner_content, render_page_content(page))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_index(posts, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, Map.get(assigns, :site_name, "Home"))
      |> Map.put(:meta, "")
      |> Map.put(:inner_content, render_post_list(posts))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_taxonomy(type, name, _items, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, "#{String.capitalize(to_string(type))}: #{name}")
      |> Map.put(:meta, "")
      |> Map.put(:inner_content, "<h1>#{name}</h1><p>Taxonomy rendering not yet implemented.</p>")

    View.scaffold(page_assigns)
  end

  # Internal renderers - these could be extracted to EEx templates in priv/layout

  defp render_meta(%Post{} = _post) do
    # Render specific meta tags for a post (e.g. description, author)
    ~s(<meta name="description" content="A blog post">)
  end

  defp render_post_content(%Post{} = post) do
    """
    <article class="prose lg:prose-xl mx-auto p-4">
      <header>
        <h1>#{post.title}</h1>
        #{if post.created_at, do: "<time>#{post.created_at}</time>", else: ""}
      </header>
      <div class="content mt-8">
        #{post.content}
      </div>
    </article>
    """
  end

  defp render_page_content(%Page{} = page) do
    """
    <article class="prose lg:prose-xl mx-auto p-4">
      <header>
        <h1>#{page.title}</h1>
      </header>
      <div class="content mt-8">
        #{page.content}
      </div>
    </article>
    """
  end

  defp render_post_list(posts) do
    list_items =
      posts
      |> Enum.map(fn post ->
        """
        <li class="my-4">
          <a href="#{post.id}" class="text-blue-600 hover:underline text-xl">#{post.title}</a>
          #{if post.created_at, do: "<span class='text-gray-500 text-sm ml-4'>#{post.created_at}</span>", else: ""}
        </li>
        """
      end)
      |> Enum.join("\n")

    """
    <div class="container mx-auto p-4">
      <h1 class="text-3xl font-bold mb-6">Recent Posts</h1>
      <ul class="list-none p-0">
        #{list_items}
      </ul>
    </div>
    """
  end
end
