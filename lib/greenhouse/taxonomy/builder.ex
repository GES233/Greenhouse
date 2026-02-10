defmodule Greenhouse.Taxonomy.Builder do
  @spec as_declarative(keyword()) :: [Orchid.Step.t()]
  def as_declarative(_opts \\ []),
    do: [
      {__MODULE__, :posts_map, :tags_posts_mapper},
      {__MODULE__, :posts_map, :series_posts_mapper},
      {__MODULE__, :posts_map, :categories_posts_mapper}
    ]

  # wip
  def posts_map_into_series(posts_map) do
    posts_map
    |> Greenhouse.Taxonomy.Series.get_id_series_pair()
    |> Greenhouse.Taxonomy.Series.get_series_posts_mapper()
  end

  # done
  def posts_map_into_tags(posts_map) do
    posts_map
    |> Greenhouse.Taxonomy.Tags.get_id_tag_pair()
    |> Greenhouse.Taxonomy.Tags.get_tags_posts_mapper()
  end

  def posts_map_into_categories(posts_map) do
    posts_map
    |> Greenhouse.Taxonomy.Categories.get_id_categories_pair()
    |> Greenhouse.Taxonomy.Categories.build_category_tree()
  end
end
