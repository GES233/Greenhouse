defmodule Greenhouse.Steps.TaxonomyBuilder do
  def as_declarative(_opts \\ []), do: [
    {__MODULE__, :posts_map, :tags_posts_mapper},
    {__MODULE__, :posts_map, :series_posts_mapper},
    {__MODULE__, :posts_map, :categories_posts_mapper},
  ]
end
