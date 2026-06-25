defmodule Greenhouse.Pipeline.IndexSteps do
  use Oi.Step, name: :index

  manifest(
    inputs: [:posts_map, :tags_map, :series_map, :cat_map],
    outputs: [index_status: :any]
  )

  @options_schema [
    theme: [
      type: :atom,
      default: Greenhouse.Theme.Default,
      doc: "Module implementing the Greenhouse.Theme behaviour"
    ],
    site_config: [
      type: :map,
      default: %{},
      doc: "Global site configuration passed to the theme"
    ],
    output_dir: [
      type: :string,
      default: "exports",
      doc: "Directory to write output files"
    ],
    page_size: [
      type: :pos_integer,
      default: 10,
      doc: "Number of posts per index page"
    ]
  ]

  routine [posts_dict, tags_posts_mapper, series_posts_mapper, categories_posts_mapper], opts do
    validated =
      opts
      |> Keyword.drop([:__orchid_workflow_ctx__, :__reporter_ctx__])
      |> NimbleOptions.validate!(@options_schema)

    theme_module = validated[:theme]
    global_assigns = validated[:site_config]
    output_dir = validated[:output_dir]

    posts = posts_dict |> Map.values() |> Enum.sort_by(& &1.created_at, {:desc, NaiveDateTime})

    pages = paginate(posts, validated[:page_size])
    total_pages = length(pages)

    pages
    |> Enum.with_index(1)
    |> Enum.each(fn {page_posts, page_num} ->
      page_assigns =
        Map.merge(global_assigns, %{
          page: page_num,
          total_pages: total_pages
        })

      html = theme_module.render_index(page_posts, page_assigns)

      path =
        if page_num == 1 do
          Path.join(output_dir, "index.html")
        else
          Path.join([output_dir, "page", to_string(page_num), "index.html"])
        end

      File.mkdir_p!(Path.dirname(path))
      File.write!(path, html)
    end)

    render_taxonomy_map(tags_posts_mapper, :tags, theme_module, global_assigns, output_dir, posts_dict)
    render_taxonomy_map(categories_posts_mapper, :categories, theme_module, global_assigns, output_dir, posts_dict)
    render_taxonomy_map(series_posts_mapper, :series, theme_module, global_assigns, output_dir, posts_dict)

    ok(:ok)
  end

  defp paginate(posts, page_size) do
    Enum.chunk_every(posts, page_size)
  end

  defp render_taxonomy_map(nil, _, _, _, _, _), do: :ok

  defp render_taxonomy_map(
         %Greenhouse.Taxonomy.CategoryItem{} = root_node,
         type,
         theme_module,
         global_assigns,
         output_dir,
         posts_dict
       ) do
    flatten_category_tree(root_node, [])
    |> Enum.each(fn {name_path, item_ids} ->
      items =
        Enum.map(item_ids, &Map.get(posts_dict, &1))
        |> Enum.reject(&is_nil/1)
        |> Enum.sort_by(& &1.created_at, {:desc, NaiveDateTime})

      html =
        theme_module.render_taxonomy(type, Enum.join(name_path, " / "), items, global_assigns)

      path = Path.join([output_dir, to_string(type), sanitize_name(name_path), "index.html"])
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, html)
    end)
  end

  defp render_taxonomy_map(mapper, type, theme_module, global_assigns, output_dir, posts_dict) do
    mapper
    |> Enum.each(fn {name, item_ids} ->
      items =
        Enum.map(item_ids, &Map.get(posts_dict, &1))
        |> Enum.reject(&is_nil/1)
        |> Enum.sort_by(& &1.created_at, {:desc, NaiveDateTime})

      html = theme_module.render_taxonomy(type, name, items, global_assigns)

      path = Path.join([output_dir, to_string(type), sanitize_name(name), "index.html"])
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, html)
    end)
  end

  defp flatten_category_tree(
         %Greenhouse.Taxonomy.CategoryItem{name: name, child: children, posts: posts},
         current_path
       ) do
    new_path = if name == "\u672a\u5f52\u7c7b" and current_path == [], do: [], else: current_path ++ [name]

    current_node_items =
      if new_path != [] and posts != [] do
        [{new_path, posts}]
      else
        []
      end

    child_items = children |> Enum.flat_map(&flatten_category_tree(&1, new_path))

    current_node_items ++ child_items
  end

  defp sanitize_name(name) when is_list(name), do: Enum.join(name, "-") |> sanitize_string()
  defp sanitize_name(name), do: to_string(name) |> sanitize_string()

  defp sanitize_string(str) do
    str
    |> String.replace(~r/[ \.\/\\]+/, "-")
  end
end
