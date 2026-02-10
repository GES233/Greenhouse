defmodule Greenhouse.Pipeline.LayoutSteps do
  alias Greenhouse.Content.{Post, Page}
  import Greenhouse.Cite.Link
  use Orchid.Step

  def run(map_with_doc_struct, _step_options) do
    {:ok,
     Orchid.Param.get_payload(map_with_doc_struct)
     |> Task.async_stream(&add_layout/1)
     |> Enum.map(fn {:ok, r} -> r end)
     |> then(&Orchid.Param.new(:any, :router_content_pair, &1))}
  end

  def add_layout(%Post{} = post) do
    {convert(post), ""}
  end

  def add_layout(%Page{} = page) do
    {convert(page), ""}
  end
end
