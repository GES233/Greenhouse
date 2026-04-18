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
    ],
    output_dir: [
      type: :string,
      default: "exports",
      doc: "Directory to write output files"
    ]
  ]

  def run(map_with_doc_struct, step_options) do
    opts =
      step_options
      |> Orchid.Steps.Helpers.drop_orchid_native()
      |> NimbleOptions.validate!(@options_schema)

    theme_module = opts[:theme]
    global_assigns = opts[:site_config]

    output_dir = opts[:output_dir]
    File.mkdir_p!(output_dir)

    {:ok,
     Orchid.Param.get_payload(map_with_doc_struct)
     |> Task.async_stream(&add_layout(&1, theme_module, global_assigns))
     |> Enum.map(fn {:ok, r} -> r end)
     |> Enum.map(fn {id, {container, html}} ->
       # convert/1 返回如 "/2024/01/post_id" 或 "/about"
       # 去除首部 "/"，防止 Path.join 将其当作绝对路径处理
       rel_path =
         Greenhouse.Cite.Link.convert(container)
         |> String.trim_leading("/")
         |> then(fn
           "" -> "index.html"
           path -> "#{path}/index.html"
         end)

       path = Path.join(output_dir, rel_path)

       # 因为目录可能是嵌套的，所以需要先创建父目录
       File.mkdir_p!(Path.dirname(path))
       File.write!(path, html)

       id
     end)
     |> then(&Orchid.Param.new(:any, :id_content_pair, &1))}
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
