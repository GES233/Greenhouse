defmodule Greenhouse.Taxonomy.Series do
  def get_id_tag_pair(posts_map) do
    posts_map
    |> Enum.map(fn {id, post} -> {id, post.index_view[:series]} end)
    |> Enum.reject(fn {_, maybe_series} -> is_nil(maybe_series) end)
  end

  # def get_series(id_series_pair)

  # def get_series_posts_mapper(id_series_pair)
end
