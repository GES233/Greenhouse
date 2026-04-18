defmodule Greenhouse.Pipeline.Recipe do
  alias Orchid.Recipe, as: R

  def build() do
    generated_root_target = nil

    R.new(
      [
        {&Greenhouse.Pipeline.ContentSteps.load_posts/2, :posts_path, :posts_map, []},
        {&Greenhouse.Pipeline.ContentSteps.load_pages/2, :page_root_path, :pages_map, []},
        Greenhouse.Media.MediaLoader.as_declarative(generated_root_target),
        {&Greenhouse.Pipeline.ContentSteps.replace_link/2, [:posts_map, :pages_map, :media_map],
         [:replaced_posts_map, :replaced_pages_map], []},
        {Greenhouse.Steps.MarkdownToHTML, [:replaced_posts_map, :bib_entry],
         :posts_map_with_doc_struct},
        {Greenhouse.Steps.MarkdownToHTML, [:replaced_pages_map, :bib_entry],
         :pages_map_with_doc_struct},
        {Greenhouse.Pipeline.TaxonomyStep, :posts_map,
         [:tags_posts_mapper, :series_posts_mapper, :categories_posts_mapper]},
        {Greenhouse.Pipeline.LayoutSteps, :posts_map_with_doc_struct, :post_ids,
         theme: Greenhouse.Theme.MobileFriendly},
        {Greenhouse.Pipeline.LayoutSteps, :pages_map_with_doc_struct, :page_ids,
         theme: Greenhouse.Theme.MobileFriendly}
      ],
      name: :build
    )
  end
end
