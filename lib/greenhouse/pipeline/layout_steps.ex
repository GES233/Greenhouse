defmodule Greenhouse.Pipeline.LayoutSteps do
  alias Greenhouse.Content.{Post, Page}
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
      doc: "Global site configuration (e.g. title, author) passed to the theme"
    ]
  ]

  def run(map_with_doc_struct, step_options) do
    opts =
      step_options
      |> Orchid.Steps.Helpers.drop_orchid_native()
      |> NimbleOptions.validate!(@options_schema)

    theme_module = opts[:theme]
    global_assigns = opts[:site_config]

    {:ok,
     Orchid.Param.get_payload(map_with_doc_struct)
     |> Task.async_stream(&add_layout(&1, theme_module, global_assigns))
     |> Enum.map(fn {:ok, r} -> r end)
     |> then(&Orchid.Param.new(:any, :router_content_pair, &1))}
  end

  def add_layout(%Post{} = post, theme, assigns) do
    # Assuming convert/1 modifies the post in some way needed before rendering
    # or you might just pass the post directly. If convert returns HTML directly, 
    # we replace it with the theme call.
    html = theme.render_post(post, assigns)
    {post.id, html}
  end

  def add_layout(%Page{} = page, theme, assigns) do
    html = theme.render_page(page, assigns)
    {page.id, html}
  end
end
