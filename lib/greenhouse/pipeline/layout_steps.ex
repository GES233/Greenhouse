defmodule Greenhouse.Pipeline.LayoutSteps do
  use Oi.Step, name: :layout
  alias Greenhouse.Content.{Post, Page}

  manifest(
    inputs: [:map_with_doc_struct],
    outputs: [ids: :id_content_pair]
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
      doc: "Global site configuration (e.g. title, author) passed to the theme"
    ],
    output_dir: [
      type: :string,
      default: "exports",
      doc: "Directory to write output files"
    ]
  ]

  routine map_with_doc_struct, opts do
    validated =
      opts
      |> Keyword.drop([:__orchid_workflow_ctx__, :__reporter_ctx__])
      |> NimbleOptions.validate!(@options_schema)

    theme_module = validated[:theme]
    global_assigns = validated[:site_config]
    output_dir = validated[:output_dir]
    File.mkdir_p!(output_dir)

    ids =
      map_with_doc_struct
      |> Task.async_stream(&add_layout(&1, theme_module, global_assigns))
      |> Enum.map(fn {:ok, r} -> r end)
      |> Enum.map(fn {id, {container, html}} ->
        rel_path =
          Greenhouse.Cite.Link.convert(container)
          |> String.trim_leading("/")
          |> then(fn
            "" -> "index.html"
            path -> "#{path}/index.html"
          end)

        path = Path.join(output_dir, rel_path)

        File.mkdir_p!(Path.dirname(path))
        File.write!(path, html)

        id
      end)

    ok(ids)
  end

  def add_layout({id, %Post{} = post}, theme, assigns) do
    html = theme.render_post(post, assigns)
    {id, {post, html}}
  end

  def add_layout({id, %Page{} = page}, theme, assigns) do
    html = theme.render_page(page, assigns)
    {id, {page, html}}
  end
end
