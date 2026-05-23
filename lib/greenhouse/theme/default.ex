defmodule Greenhouse.Theme.Default do
  @moduledoc """
  The default built-in EEx-based theme for Greenhouse.
  """
  @behaviour Greenhouse.Theme

  alias Greenhouse.Content.{Post, Page}
  alias Greenhouse.Layout.View

  @impl true
  def render_post(%Post{} = post, assigns) do
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
      |> Map.put(:meta, render_meta(page))
      |> Map.put(:inner_content, render_page_content(page))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_index(posts, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, Map.get(assigns, :site_name, "Home"))
      |> Map.put(:meta, "")
      |> Map.put(:inner_content, render_post_list(posts, assigns))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_taxonomy(type, name, _items, assigns) do
    taxonomy_type = case type do
      any ->
        IO.inspect(any)

        String.capitalize(to_string(type))
    end

    page_assigns =
      assigns
      |> Map.put(:page_title, "#{taxonomy_type}: #{name}")
      |> Map.put(:meta, "")
      |> Map.put(:inner_content, "<h1>#{name}</h1><p>Taxonomy rendering not yet implemented.</p>")

    View.scaffold(page_assigns)
  end

  defp render_meta(post_or_page) do
    options = Greenhouse.Layout.Components.get_options(post_or_page) || %{}

    View.meta(%{options: options, maybe_extra: ""})
  end

  defp render_post_content(%Post{} = post) do
    html_body =
      case post.doc_struct do
        %{body: body} when is_list(body) -> IO.iodata_to_binary(body)
        %{body: body} when is_binary(body) -> body
        doc -> Map.get(doc, :body, post.content)
      end

    """
    <article class="prose lg:prose-xl mx-auto p-4 max-w-4xl">
      <header class="mb-8 border-b pb-4">
        <h1 class="text-4xl font-serif text-gray-900">#{post.title}</h1>
        <div class="mt-2 text-gray-500 text-sm">
          #{if post.created_at, do: "<time>#{post.created_at}</time>", else: ""}
        </div>
      </header>
      <div class="content font-serif text-gray-800 leading-relaxed text-lg space-y-6">
        #{html_body}
      </div>
    </article>
    """
  end

  defp render_page_content(%Page{} = page) do
    html_body =
      case page.doc_struct do
        %{body: body} when is_list(body) -> IO.iodata_to_binary(body)
        %{body: body} when is_binary(body) -> body
        doc -> Map.get(doc, :body, page.content)
      end

    """
    <article class="prose lg:prose-xl mx-auto p-4 max-w-4xl">
      <header class="mb-8 border-b pb-4">
        <h1 class="text-4xl font-serif text-gray-900">#{page.title}</h1>
      </header>
      <div class="content font-serif text-gray-800 leading-relaxed text-lg space-y-6">
        #{html_body}
      </div>
    </article>
    """
  end

  defp render_post_list(posts, assigns) do
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

    pagination_nav = render_pagination(assigns)

    """
    <div class="container mx-auto p-4">
      <h1 class="text-3xl font-bold mb-6">Recent Posts</h1>
      <ul class="list-none p-0">
        #{list_items}
      </ul>
      #{pagination_nav}
    </div>
    """
  end

  defp render_pagination(assigns) do
    page = Map.get(assigns, :page)
    total_pages = Map.get(assigns, :total_pages)

    if page && total_pages && total_pages > 1 do
      prev_link = if page > 1, do: pagination_link(page - 1), else: ""
      next_link = if page < total_pages, do: pagination_link(page + 1), else: ""

      """
      <nav class="flex justify-center gap-4 mt-8 pt-4 border-t">
        <span class="text-gray-400 text-sm">Page #{page} / #{total_pages}</span>
        #{prev_link}#{next_link}
      </nav>
      """
    else
      ""
    end
  end

  defp pagination_link(1), do: "<a href='/' class='text-blue-600 hover:underline'>Home</a>"
  defp pagination_link(n), do: "<a href='/page/#{n}/' class='text-blue-600 hover:underline'>Page #{n}</a>"
end
