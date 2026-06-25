defmodule Greenhouse.Pipeline.TaxonomyStep do
  use Oi.Step, name: :taxonomy
  import Greenhouse.Taxonomy.Builder

  manifest(
    inputs: [:posts_map],
    outputs: [
      tags_posts_mapper: :index_posts_mapper,
      series_posts_mapper: :index_posts_mapper,
      categories_posts_mapper: :index_posts_mapper
    ]
  )

  routine posts_map, _opts do
    tags = posts_map_into_tags(posts_map)
    series = posts_map_into_series(posts_map)
    categories = posts_map_into_categories(posts_map)

    ok({tags, series, categories})
  end
end
