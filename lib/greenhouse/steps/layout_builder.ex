defmodule Greenhouse.Steps.LayoutBuilder do
  use Orchid.Step

  def as_declarative(_opts \\ []), do: [
    # Seperate layout and write
    {__MODULE__, [:posts_map_with_doc_struct, :generated_posts_entrance], :post_router_content_pair},
    {__MODULE__, [:pages_map_with_doc_struct, :generated_pages_entrance], :page_router_content_pair},
  ]

  def run([_map_with_doc_struct, _target_entrance], _step_options) do
    {:ok, Orchid.Param.new(:any, :router_content_pair)}
  end

  # def add_layout(page_or_post) do
end
