defmodule Greenhouse.Pipeline.Recipe do
  alias Orchid.Recipe, as: R

  def build() do
    R.new(
      [
        {&Greenhouse.Pipeline.ContentSteps.load_posts/2, :posts_path, :posts_map, []},
        {&Greenhouse.Pipeline.ContentSteps.load_pages/2, :page_root_path, :pages_map, []},
        Greenhouse.Media.MediaLoader.as_declarative(),
        {&Greenhouse.Pipeline.ContentSteps.replace_link/2, [:posts_map, :pages_map, :media_map],
         [:replaced_posts_map, :replaced_pages_map], []},
        {Greenhouse.Steps.MarkdownToHTML, [:replaced_posts_map, :bib_entry],
         :posts_map_with_doc_struct},
        {Greenhouse.Steps.MarkdownToHTML, [:replaced_pages_map, :bib_entry],
         :pages_map_with_doc_struct},
        {Greenhouse.Pipeline.TaxonomyStep, :posts_map,
         [:tags_posts_mapper, :series_posts_mapper, :categories_posts_mapper]}
        # {Greenhouse.Layout.Builder, :posts_map_with_doc_struct, :post_router_content_pair},
        # {Greenhouse.Layout.Builder, :pages_map_with_doc_struct, :page_router_content_pair}
      ],
      name: :build
    )
  end
end
