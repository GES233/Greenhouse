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
      |> Map.put(:inner_content, render_page_frame(render_post_content(post), assigns))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_page(%Page{} = page, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, page.title || "Page")
      |> Map.put(:meta, render_meta(page))
      |> Map.put(:inner_content, render_page_frame(render_page_content(page), assigns))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_index(posts, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, Map.get(assigns, :site_name, "Home"))
      |> Map.put(:meta, "")
      |> Map.put(:inner_content, render_page_frame(render_post_list(posts, assigns), assigns))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_taxonomy(type, name, items, assigns) do
    taxonomy_label =
      case type do
        :category -> "Category"
        :tag -> "Tag"
        :series -> "Series"
        other -> String.capitalize(to_string(other))
      end

    page_assigns =
      assigns
      |> Map.put(:page_title, "#{taxonomy_label}: #{name}")
      |> Map.put(:meta, "")
      |> Map.put(:inner_content, render_page_frame(render_taxonomy_content(type, name, items), assigns))

    View.scaffold(page_assigns)
  end

  
  # -- Page frame --

  defp render_page_frame(content, assigns) do
    site_name = Map.get(assigns, :site_name, "Greenhouse")
    render_header(site_name) <> "<main class=\"min-h-[70vh]\">" <> content <> "</main>" <> render_footer(site_name)
  end

  defp render_header(site_name) do
    """
    <header class="border-b border-base-300 bg-base-100/80 backdrop-blur sticky top-0 z-10">
      <nav class="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <a href="/" class="text-xl font-semibold tracking-tight text-base-content no-underline">
          #{site_name}
        </a>
        <div class="flex gap-6 text-sm">
          <a href="/" class="text-base-content/70 hover:text-base-content transition-colors no-underline">Home</a>
          <a href="/about/" class="text-base-content/70 hover:text-base-content transition-colors no-underline">About</a>
          <a href="/categories/" class="text-base-content/70 hover:text-base-content transition-colors no-underline">Categories</a>
        </div>
      </nav>
    </header>
    """
  end

  defp render_footer(site_name) do
    """
    <footer class="border-t border-base-300 mt-16 py-8 text-center text-sm text-base-content/50">
      <p>#{site_name} &mdash; Powered by Greenhouse</p>
    </footer>
    """
  end

  # -- Meta --

  defp render_meta(post_or_page) do
    options = Greenhouse.Layout.Components.get_options(post_or_page) || %{}
    View.meta(%{options: options, maybe_extra: ""})
  end

  # -- Post content --

  defp render_post_content(%Post{} = post) do
    html_body = extract_body(post)
    created = format_date(post.created_at)
    date_html = if created, do: "<time class=\"text-sm text-base-content/50\">#{created}</time>", else: ""

    """
    <article class="prose lg:prose-xl mx-auto px-4 py-8 max-w-4xl">
      <header class="mb-10 border-b border-base-300 pb-6">
        <h1 class="text-[var(--ts-4)] font-sans font-semibold tracking-tight text-base-content mb-3">#{post.title}</h1>
        #{date_html}
      </header>
      <div class="content">
        #{html_body}
      </div>
    </article>
    """
  end

  # -- Page content --

  defp render_page_content(%Page{} = page) do
    html_body = extract_body(page)

    """
    <article class="prose lg:prose-xl mx-auto px-4 py-8 max-w-4xl">
      <header class="mb-10 border-b border-base-300 pb-6">
        <h1 class="text-[var(--ts-4)] font-sans font-semibold tracking-tight text-base-content mb-3">#{page.title}</h1>
      </header>
      <div class="content">
        #{html_body}
      </div>
    </article>
    """
  end

  # -- Post list --

  defp render_post_list(posts, assigns) do
    years = posts |> Enum.group_by(&extract_year/1) |> Enum.sort(:desc)

    year_sections =
      years
      |> Enum.map(fn {year, year_posts} ->
        items =
          year_posts
          |> Enum.map(fn post ->
            date_str = format_date_short(post.created_at)
            tags_html = render_tag_list(post)

            """
            <article class="group py-3 border-b border-base-200 last:border-0">
              <a href="#{post.id}" class="block no-underline hover:bg-base-200/50 -mx-2 px-2 py-1 rounded transition-colors">
                <div class="flex items-baseline gap-4">
                  <time class="text-xs text-base-content/40 tabular-nums shrink-0 w-16 text-right">#{date_str}</time>
                  <span class="text-base text-base-content font-medium group-hover:text-primary transition-colors">#{post.title}</span>
                </div>
                #{tags_html}
              </a>
            </article>
            """
          end)
          |> Enum.join("\n")

        """
        <section class="mb-8">
          <h2 class="text-lg font-semibold text-base-content/60 mb-3 font-sans tracking-wide">#{year}</h2>
          #{items}
        </section>
        """
      end)
      |> Enum.join("\n")

    pagination_nav = render_pagination(assigns)

    """
    <div class="max-w-4xl mx-auto px-4 py-8">
      #{year_sections}
      #{pagination_nav}
    </div>
    """
  end

  defp render_tag_list(%Post{index_view: %{categories: cats}}) when is_list(cats) and cats != [] do
    tags =
      cats
      |> Enum.take(3)
      |> Enum.map(&("<span class=\"text-xs text-base-content/40 bg-base-200 px-1.5 py-0.5 rounded\">#{&1}</span>"))
      |> Enum.join(" ")

    "<div class=\"ml-20 mt-1\">#{tags}</div>"
  end

  defp render_tag_list(_post), do: ""

  defp extract_year(%Post{created_at: %DateTime{year: year}}), do: year
  defp extract_year(%Post{created_at: %Date{year: year}}), do: year
  defp extract_year(%Post{created_at: %NaiveDateTime{year: year}}), do: year
  defp extract_year(_post), do: 0

  # -- Taxonomy --

  defp render_taxonomy_content(_type, name, items) do
    item_links =
      case items do
        list when is_list(list) ->
          list
          |> Enum.map(fn item ->
            id = if is_map(item), do: Map.get(item, :id), else: item
            title = if is_map(item), do: Map.get(item, :title) || id, else: id
            "<li><a href=\"#{id}\" class=\"text-primary hover:underline text-lg\">#{title}</a></li>"
          end)
          |> Enum.join("\n")

        _ ->
          "<li class=\"text-base-content/50\">No items yet.</li>"
      end

    """
    <div class="max-w-4xl mx-auto px-4 py-8">
      <h1 class="text-[var(--ts-3)] font-sans font-semibold tracking-tight text-base-content mb-6">#{name}</h1>
      <ul class="space-y-3 list-none pl-0">
        #{item_links}
      </ul>
    </div>
    """
  end

  # -- Pagination --

  defp render_pagination(assigns) do
    page = Map.get(assigns, :page)
    total_pages = Map.get(assigns, :total_pages)

    if page && total_pages && total_pages > 1 do
      prev_html =
        if page > 1 do
          "<a href=\"#{pagination_href(page - 1)}\" class=\"text-primary hover:underline text-sm\">&larr; Prev</a>"
        else
          "<span class=\"text-base-content/20 text-sm\">&larr; Prev</span>"
        end

      next_html =
        if page < total_pages do
          "<a href=\"#{pagination_href(page + 1)}\" class=\"text-primary hover:underline text-sm\">Next &rarr;</a>"
        else
          "<span class=\"text-base-content/20 text-sm\">Next &rarr;</span>"
        end

      """
      <nav class="flex justify-center items-center gap-6 mt-12 pt-6 border-t border-base-200">
        #{prev_html}
        <span class="text-sm text-base-content/50">Page #{page} / #{total_pages}</span>
        #{next_html}
      </nav>
      """
    else
      ""
    end
  end

  defp pagination_href(1), do: "/"
  defp pagination_href(n), do: "/page/#{n}/"

  # -- Helpers --

  defp extract_body(%{doc_struct: %{body: body}}) when is_list(body) do
    IO.iodata_to_binary(body)
  end

  defp extract_body(%{doc_struct: %{body: body}}) when is_binary(body) do
    body
  end

  defp extract_body(%{doc_struct: doc}) do
    Map.get(doc, :body, "")
  end

  defp extract_body(%{content: content}) do
    content
  end

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d")
  end

  defp format_date(%Date{} = d) do
    Calendar.strftime(d, "%Y-%m-%d")
  end

  defp format_date(%NaiveDateTime{} = ndt) do
    Calendar.strftime(ndt, "%Y-%m-%d")
  end

  defp format_date(_), do: nil

  defp format_date_short(%DateTime{} = dt) do
    Calendar.strftime(dt, "%m-%d")
  end

  defp format_date_short(%Date{} = d) do
    Calendar.strftime(d, "%m-%d")
  end

  defp format_date_short(%NaiveDateTime{} = ndt) do
    Calendar.strftime(ndt, "%m-%d")
  end

  defp format_date_short(_), do: ""
end
