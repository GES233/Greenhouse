defmodule Greenhouse.Pipeline.IndexSteps do
  use Orchid.Step

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
    ]
  ]

  def run([posts_map_param, tags_map, series_map, cat_map], step_options) do
    opts =
      step_options
      |> Orchid.Steps.Helpers.drop_orchid_native()
      |> NimbleOptions.validate!(@options_schema)

    theme_module = opts[:theme]
    global_assigns = opts[:site_config]
    output_dir = opts[:output_dir]

    posts_dict = Orchid.Param.get_payload(posts_map_param)
    posts = posts_dict |> Map.values() |> Enum.sort_by(& &1.created_at, {:desc, NaiveDateTime})
    
    # 1. Render Index
    index_html = theme_module.render_index(posts, global_assigns)
    index_path = Path.join(output_dir, "index.html")
    File.write!(index_path, index_html)

    # 2. Render Taxonomies (tags, categories, series)
    tags_posts_mapper = Orchid.Param.get_payload(tags_map)
    series_posts_mapper = Orchid.Param.get_payload(series_map)
    categories_posts_mapper = Orchid.Param.get_payload(cat_map)

    render_taxonomy_map(tags_posts_mapper, :tags, theme_module, global_assigns, output_dir, posts_dict)
    render_taxonomy_map(categories_posts_mapper, :categories, theme_module, global_assigns, output_dir, posts_dict)
    render_taxonomy_map(series_posts_mapper, :series, theme_module, global_assigns, output_dir, posts_dict)

    {:ok, Orchid.Param.new(:index_status, :any, :ok)}
  end

  defp render_taxonomy_map(nil, _, _, _, _, _), do: :ok
  defp render_taxonomy_map(%Greenhouse.Taxonomy.CategoryItem{} = root_node, type, theme_module, global_assigns, output_dir, posts_dict) do
    # For Categories, it's a tree structure, so we need to flatten it or render it recursively
    # Here we flatten the tree into a map of {category_path_list, posts_list} to fit the existing logic
    flatten_category_tree(root_node, [])
    |> Enum.each(fn {name_path, item_ids} ->
      items = Enum.map(item_ids, &Map.get(posts_dict, &1)) |> Enum.reject(&is_nil/1) |> Enum.sort_by(& &1.created_at, {:desc, NaiveDateTime})
      html = theme_module.render_taxonomy(type, Enum.join(name_path, " / "), items, global_assigns)
      
      path = Path.join([output_dir, to_string(type), sanitize_name(name_path), "index.html"])
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, html)
    end)
  end

  defp render_taxonomy_map(mapper, type, theme_module, global_assigns, output_dir, posts_dict) do
    mapper
    |> Enum.each(fn {name, item_ids} ->
      items = Enum.map(item_ids, &Map.get(posts_dict, &1)) |> Enum.reject(&is_nil/1) |> Enum.sort_by(& &1.created_at, {:desc, NaiveDateTime})
      html = theme_module.render_taxonomy(type, name, items, global_assigns)
      
      path = Path.join([output_dir, to_string(type), sanitize_name(name), "index.html"])
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, html)
    end)
  end

  defp flatten_category_tree(%Greenhouse.Taxonomy.CategoryItem{name: name, child: children, posts: posts}, current_path) do
    # Skip the "未归类" root node name if current_path is empty
    new_path = if name == "未归类" and current_path == [], do: [], else: current_path ++ [name]
    
    current_node_items = if new_path != [] and posts != [] do
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