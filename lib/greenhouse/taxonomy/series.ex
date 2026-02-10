defmodule Greenhouse.Taxonomy.Series do
  def get_id_series_pair(posts_map) do
    posts_map
    |> Enum.map(fn {id, post} -> {id, post.index_view[:series]} end)
    |> Enum.reject(fn {_, maybe_series} -> is_nil(maybe_series) end)
  end

  def get_series(id_series_pair) do
    id_series_pair
    |> Enum.reduce([], fn {_, series}, acc -> [series | acc] end)
    |> List.flatten()
    |> Enum.uniq()
  end

  def get_series_posts_mapper(id_series_pair) do
    id_series_pair
    |> Enum.map(fn {id, series} -> {series, id}
    end)
    |> Enum.group_by(fn {series, _id} -> series end, fn {_series, id} -> id end)
    |> Map.new()
  end
end
