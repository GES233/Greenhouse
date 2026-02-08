defmodule Greenhouse.Taxonomy.Builder do
  @spec as_declarative(keyword()) :: [Orchid.Step.t()]
  def as_declarative(_opts \\ []),
    do: [
      {__MODULE__, :posts_map, :tags_posts_mapper},
      {__MODULE__, :posts_map, :series_posts_mapper},
      {__MODULE__, :posts_map, :categories_posts_mapper}
    ]
end
