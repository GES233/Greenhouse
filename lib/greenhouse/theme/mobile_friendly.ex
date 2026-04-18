defmodule Greenhouse.Theme.MobileFriendly do
  @moduledoc """
  A mobile-friendly theme for Greenhouse designed for D:\\Blog content.
  It uses responsive utility classes (e.g. Tailwind) to ensure it looks great on both mobile and desktop.
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
      |> Map.put(:inner_content, render_post_list(posts))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_taxonomy(type, name, _items, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, "#{String.capitalize(to_string(type))}: #{name}")
      |> Map.put(:meta, "")
      |> Map.put(
        :inner_content,
        "<div class=\"px-4 py-8 md:px-8 max-w-4xl mx-auto\"><h1 class=\"text-3xl font-bold\">#{name}</h1><p class=\"mt-4\">Taxonomy rendering not yet implemented.</p></div>"
      )

    View.scaffold(page_assigns)
  end

  defp render_meta(post_or_page) do
    options = Greenhouse.Layout.Components.get_options(post_or_page) || %{}
    # Include viewport meta tag for mobile responsiveness in the scaffold template.
    # We can also inject Tailwind via CDN for styling purposes, but ideally it should be processed.
    # For now, adding Tailwind CDN to the meta block so classes take effect.
    meta_html = View.meta(%{options: options, maybe_extra: ""})
    tailwind_cdn = """
    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.7.2/dist/full.min.css" rel="stylesheet" type="text/css" />
    <script src="https://cdn.tailwindcss.com?plugins=typography"></script>
    """
    viewport_meta = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"

    # We combine them if not already in scaffold
    "#{tailwind_cdn}\n#{viewport_meta}\n#{meta_html}"
  end

  defp render_post_content(%Post{} = post) do
    html_body = extract_body(post)

    """
    <div class="bg-gray-50 min-h-screen">
      <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
        <article class="bg-white rounded-xl shadow-sm p-6 sm:p-8 md:p-12">
          <header class="mb-8 md:mb-12 border-b border-gray-100 pb-6 md:pb-8">
            <h1 class="text-3xl sm:text-4xl md:text-5xl font-extrabold text-gray-900 leading-tight mb-4 tracking-tight">#{post.title}</h1>
            <div class="flex flex-wrap items-center text-sm sm:text-base text-gray-500 gap-4">
              #{if post.created_at, do: "<time class=\"flex items-center\"><svg class=\"w-4 h-4 mr-2\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z\"></path></svg>#{post.created_at}</time>", else: ""}
            </div>
          </header>
          
          <div class="prose prose-sm sm:prose-base lg:prose-lg max-w-none text-gray-700 leading-relaxed 
                      prose-headings:font-bold prose-headings:text-gray-900 
                      prose-a:text-blue-600 prose-a:no-underline hover:prose-a:underline
                      prose-img:rounded-lg prose-img:shadow-md
                      prose-pre:bg-gray-800 prose-pre:text-gray-100 prose-pre:rounded-lg
                      prose-blockquote:border-l-4 prose-blockquote:border-blue-500 prose-blockquote:bg-gray-50 prose-blockquote:py-1 prose-blockquote:px-4 prose-blockquote:not-italic prose-blockquote:text-gray-600">
            #{html_body}
          </div>
        </article>
      </main>
    </div>
    """
  end

  defp render_page_content(%Page{} = page) do
    html_body = extract_body(page)

    """
    <div class="bg-gray-50 min-h-screen">
      <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
        <article class="bg-white rounded-xl shadow-sm p-6 sm:p-8 md:p-12">
          <header class="mb-8 md:mb-12 border-b border-gray-100 pb-6 md:pb-8">
            <h1 class="text-3xl sm:text-4xl md:text-5xl font-extrabold text-gray-900 leading-tight tracking-tight">#{page.title}</h1>
          </header>
          
          <div class="prose prose-sm sm:prose-base lg:prose-lg max-w-none text-gray-700 leading-relaxed
                      prose-headings:font-bold prose-headings:text-gray-900
                      prose-a:text-blue-600 prose-a:no-underline hover:prose-a:underline">
            #{html_body}
          </div>
        </article>
      </main>
    </div>
    """
  end

  defp render_post_list(posts) do
    list_items =
      posts
      |> Enum.map(fn post ->
        """
        <article class="bg-white rounded-xl shadow-sm hover:shadow-md transition-shadow duration-200 overflow-hidden">
          <a href="#{post.id}" class="block p-6 sm:p-8">
            <h2 class="text-xl sm:text-2xl font-bold text-gray-900 mb-2 group-hover:text-blue-600 transition-colors">#{post.title}</h2>
            #{if post.created_at, do: "<div class=\"text-sm text-gray-500 flex items-center mt-3\"><svg class=\"w-4 h-4 mr-2\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z\"></path></svg>#{post.created_at}</div>", else: ""}
          </a>
        </article>
        """
      end)
      |> Enum.join("\n")

    """
    <div class="bg-gray-50 min-h-screen py-8 md:py-12">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <header class="mb-10 sm:mb-12">
          <h1 class="text-3xl sm:text-4xl font-extrabold text-gray-900">Recent Posts</h1>
        </header>
        <div class="grid gap-6 md:gap-8">
          #{list_items}
        </div>
      </div>
    </div>
    """
  end

  defp extract_body(item) do
    case item.doc_struct do
      %{body: body} when is_list(body) -> IO.iodata_to_binary(body)
      %{body: body} when is_binary(body) -> body
      doc -> Map.get(doc, :body, item.content)
    end
  end
end
