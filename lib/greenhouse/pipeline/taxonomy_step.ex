defmodule Greenhouse.Pipeline.TaxonomyStep do
  use Orchid.Step
  import Greenhouse.Taxonomy.Builder
  import Orchid.ParamFactory

  def run(%Orchid.Param{payload: posts_map}, _step_options) do
    tags_posts_mapper = posts_map_into_tags(posts_map)
    series_posts_mapper = posts_map_into_series(posts_map)
    categories_posts_mapper = posts_map_into_categories(posts_map)

    {:ok,
     [
       to_param(tags_posts_mapper, :index_posts_mapper),
       to_param(series_posts_mapper, :index_posts_mapper),
       to_param(categories_posts_mapper, :index_posts_mapper)
     ]}
  end
end
