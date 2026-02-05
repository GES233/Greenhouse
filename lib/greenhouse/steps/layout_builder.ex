defmodule Greenhouse.Steps.LayoutBuilder do
  alias Greenhouse.Params.{Post, Page, Link}
  use Orchid.Step

  def as_declarative(_opts \\ []), do: [
    # Seperate layout and write process.
    {__MODULE__, :posts_map_with_doc_struct, :post_router_content_pair},
    {__MODULE__, :pages_map_with_doc_struct, :page_router_content_pair},
  ]

  def run(map_with_doc_struct, _step_options) do
    {:ok,
     Orchid.Param.get_payload(map_with_doc_struct)
     |> Task.async_stream(&add_layout/1)
     |> Enum.map(fn {:ok, r} -> r end)
     |> then(&Orchid.Param.new(:any, :router_content_pair, &1))}
  end

  def add_layout(%Post{} = post) do
    {Link.convert(post), ""}
  end

  def add_layout(%Page{} = page) do
    {Link.convert(page), ""}
  end
end
