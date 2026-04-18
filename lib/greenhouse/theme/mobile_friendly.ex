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
      |> Map.put(:meta, render_meta(nil))
      |> Map.put(:inner_content, render_post_list(posts))

    View.scaffold(page_assigns)
  end

  @impl true
  def render_taxonomy(type, name, items, assigns) do
    page_assigns =
      assigns
      |> Map.put(:page_title, "#{String.capitalize(to_string(type))}: #{name}")
      |> Map.put(:meta, render_meta(nil))
      |> Map.put(:inner_content, render_taxonomy_content(type, name, items))

    View.scaffold(page_assigns)
  end

  defp render_taxonomy_content(type, name, posts) do
    # Now we have the actual full Post objects!
    list_items =
      posts
      |> Enum.map(fn post ->
        link = Greenhouse.Cite.Link.convert(post)
        """
        <article class="bg-base-100 rounded-xl shadow-sm hover:shadow-md transition-shadow duration-200 overflow-hidden">
          <a href="#{link}" class="block p-6 sm:p-8">
            <h2 class="text-xl sm:text-2xl font-bold text-base-content mb-2 group-hover:text-primary transition-colors">#{post.title}</h2>
            #{if post.created_at, do: "<div class=\"text-sm text-base-content/70 flex items-center mt-3\"><svg class=\"w-4 h-4 mr-2\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z\"></path></svg>#{post.created_at}</div>", else: ""}
          </a>
        </article>
        """
      end)
      |> Enum.join("\n")

    """
    #{theme_toggle_button()}
    <div class="bg-base-200 min-h-screen py-8 md:py-12">
      <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <header class="mb-10 sm:mb-12">
          <div class="text-sm font-bold text-primary mb-2 uppercase tracking-wider">#{type}</div>
          <h1 class="text-3xl sm:text-4xl md:text-5xl font-extrabold text-base-content leading-tight tracking-tight">#{name}</h1>
          <p class="mt-4 text-base-content/70">#{length(posts)} posts in this #{type}</p>
        </header>

        <div class="grid gap-6 md:gap-8">
          #{if length(posts) > 0, do: list_items, else: "<p class=\"text-base-content/60\">No posts found.</p>"}
        </div>
      </main>
    </div>
    """
  end

  defp render_meta(post_or_page) do
    options = Greenhouse.Layout.Components.get_options(post_or_page) || %{}
    # Include viewport meta tag for mobile responsiveness in the scaffold template.
    # We can also inject Tailwind via CDN for styling purposes, but ideally it should be processed.
    # For now, adding Tailwind CDN to the meta block so classes take effect.
    meta_html = View.meta(%{options: options, maybe_extra: ""})
    tailwind_cdn = """
    <link rel="stylesheet" href="/assets/app.css">
    """
    viewport_meta = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"

    # We combine them if not already in scaffold
    "#{tailwind_cdn}\n#{viewport_meta}\n#{meta_html}\n#{theme_toggle_script()}"
  end

  defp theme_toggle_script do
    """
    <script>
      // Automatically applied if saved in localStorage
      if (localStorage.getItem("theme") === "noctilucent" || (!("theme" in localStorage) && window.matchMedia("(prefers-color-scheme: dark)").matches)) {
        document.documentElement.setAttribute("data-theme", "noctilucent");
      } else {
        document.documentElement.setAttribute("data-theme", "core-cream-soup");
      }

      function toggleTheme() {
        const html = document.documentElement;
        const currentTheme = html.getAttribute("data-theme");
        const newTheme = currentTheme === "noctilucent" ? "core-cream-soup" : "noctilucent";

        html.setAttribute("data-theme", newTheme);
        localStorage.setItem("theme", newTheme);
      }
    </script>
    """
  end

  defp theme_toggle_button do
    """
    <div class="fixed top-4 right-4 z-50">
      <button onclick="toggleTheme()" class="btn btn-circle btn-ghost btn-sm bg-base-200/50 backdrop-blur" aria-label="Toggle Theme">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z" />
        </svg>
      </button>
    </div>
    """
  end

  defp render_post_content(%Post{} = post) do
    html_body = extract_body(post)

    # Convert progress atom or list to a friendly string
    progress_label = case post.progress do
      [state, progress_num] when is_atom(state) and is_integer(progress_num) ->
        "#{format_state(state)} (#{progress_num}%)"
      [state | _] when is_atom(state) ->
        format_state(state)
      :wip -> "Work in Progress"
      :draft -> "Draft"
      :review -> "Needs Review"
      :final -> "Final"
      other -> String.capitalize(to_string(other))
    end

    """
    #{theme_toggle_button()}
    <div class="min-h-screen">
      <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
        <article class="bg-base-100 rounded-xl shadow-sm p-6 sm:p-8 md:p-12">
          <header class="mb-8 md:mb-12 border-b border-base-300 pb-6 md:pb-8">
            <h1 class="text-3xl sm:text-4xl md:text-5xl font-extrabold leading-tight mb-4 tracking-tight">#{post.title}</h1>
            <div class="flex flex-wrap items-center text-sm sm:text-base text-base-content/70 gap-4 mb-4">
              #{if post.created_at, do: "<time class=\"flex items-center\"><svg class=\"w-4 h-4 mr-2\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z\"></path></svg>#{post.created_at}</time>", else: ""}
              <div class="badge badge-outline badge-sm">#{progress_label}</div>
            </div>
            #{render_post_taxonomies(post)}
          </header>

          <div class="prose prose-sm sm:prose-base lg:prose-lg max-w-none leading-relaxed
                      prose-headings:font-bold
                      prose-a:no-underline hover:prose-a:underline
                      prose-img:rounded-lg prose-img:shadow-md
                      prose-pre:rounded-lg
                      prose-blockquote:border-l-4 prose-blockquote:py-1 prose-blockquote:px-4 prose-blockquote:not-italic">
            #{render_toc(post)}
            #{html_body}
            #{render_footnotes(post)}
            #{render_bibliography(post)}
          </div>
        </article>
      </main>
    </div>
    """
  end

  defp render_post_taxonomies(%Post{index_view: %{tags: tags, categories: categories}}) do
    categories_html = if is_list(categories) and length(categories) > 0 do
      cats = categories
        |> Enum.reject(&(&1 == []))
        |> Enum.map(fn
          cat_path when is_list(cat_path) -> 
            link = Greenhouse.Cite.Link.convert({:category, cat_path})
            name = Enum.join(cat_path, " / ")
            "<a href=\"#{link}\" class=\"text-primary hover:underline cursor-pointer\">#{name}</a>"
          cat -> 
            link = Greenhouse.Cite.Link.convert({:category, cat})
            name = to_string(cat)
            "<a href=\"#{link}\" class=\"text-primary hover:underline cursor-pointer\">#{name}</a>"
        end)
        |> Enum.join("<span class=\"mx-2 text-base-content/40\">•</span>")

      if cats != "" do
        """
        <div class="flex items-center flex-wrap text-sm gap-2 mt-2">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 text-base-content/60"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z" /></svg>
          #{cats}
        </div>
        """
      else
        ""
      end
    else
      ""
    end

    tags_html = if is_list(tags) and length(tags) > 0 do
      tags_list = tags 
        |> Enum.map(fn tag -> 
          link = Greenhouse.Cite.Link.convert({:tag, tag})
          "<a href=\"#{link}\" class=\"badge badge-ghost badge-sm hover:badge-primary transition-colors\">##{tag}</a>"
        end) 
        |> Enum.join(" ")
      """
      <div class="flex items-center flex-wrap gap-2 mt-3">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 text-base-content/60"><path stroke-linecap="round" stroke-linejoin="round" d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z" /><path stroke-linecap="round" stroke-linejoin="round" d="M6 6h.008v.008H6V6Z" /></svg>
        #{tags_list}
      </div>
      """
    else
      ""
    end

    categories_html <> tags_html
  end

  defp render_page_content(%Page{} = page) do
    html_body = extract_body(page)

    """
    #{theme_toggle_button()}
    <div class="bg-base-200 min-h-screen">
      <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
        <article class="bg-base-100 rounded-xl shadow-sm p-6 sm:p-8 md:p-12">
          <header class="mb-8 md:mb-12 border-b border-base-300 pb-6 md:pb-8">
            <h1 class="text-3xl sm:text-4xl md:text-5xl font-extrabold leading-tight tracking-tight">#{page.title}</h1>
          </header>

          <div class="prose prose-sm sm:prose-base lg:prose-lg max-w-none leading-relaxed
                      prose-headings:font-bold
                      prose-a:no-underline hover:prose-a:underline">
            #{render_toc(page)}
            #{html_body}
            #{render_footnotes(page)}
            #{render_bibliography(page)}
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
        link = Greenhouse.Cite.Link.convert(post)
        """
        <article class="bg-base-100 rounded-xl shadow-sm hover:shadow-md transition-shadow duration-200 overflow-hidden">
          <a href="#{link}" class="block p-6 sm:p-8">
            <h2 class="text-xl sm:text-2xl font-bold text-base-content mb-2 group-hover:text-primary transition-colors">#{post.title}</h2>
            #{if post.created_at, do: "<div class=\"text-sm text-base-content/70 flex items-center mt-3\"><svg class=\"w-4 h-4 mr-2\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z\"></path></svg>#{post.created_at}</time></div>", else: ""}
          </a>
        </article>
        """
      end)
      |> Enum.join("\n")

    """
    #{theme_toggle_button()}
    <div class="bg-base-200 min-h-screen py-8 md:py-12">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <header class="mb-10 sm:mb-12">
          <h1 class="text-3xl sm:text-4xl font-extrabold text-base-content">Recent Posts</h1>
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

  defp render_toc(%{doc_struct: %{toc: toc}}) when is_binary(toc) and toc != "", do: "<nav class=\"toc mb-8 p-4 bg-base-200 rounded-lg\">#{toc}</nav>"
  defp render_toc(_), do: ""

  defp render_footnotes(%{doc_struct: %{footnotes: footnotes}}) when is_binary(footnotes) and footnotes != "" do
    """
    <div class="footnotes mt-12 pt-8 border-t border-base-300">
      <h3 class="text-xl font-bold mb-4">Footnotes</h3>
      #{footnotes}
    </div>
    """
  end
  defp render_footnotes(_), do: ""

  defp render_bibliography(%{doc_struct: %{bibliography: bib}}) when is_binary(bib) and bib != "" do
    """
    <div class="bibliography mt-12 pt-8 border-t border-base-300">
      <h3 class="text-xl font-bold mb-4">References</h3>
      #{bib}
    </div>
    """
  end
  defp render_bibliography(_), do: ""

  defp format_state(:wip), do: "Work in Progress"
  defp format_state(:draft), do: "Draft"
  defp format_state(:longterm), do: "Long Term"
  defp format_state(:blocking), do: "Blocked"
  defp format_state(state), do: String.capitalize(to_string(state))
end
