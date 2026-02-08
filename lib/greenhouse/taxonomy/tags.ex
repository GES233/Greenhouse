defmodule Greenhouse.Taxonomy.Tags do
  def get_id_tag_pair(posts_map) do
    Enum.map(posts_map, fn {id, post} -> {id, post.index_view[:tags]} end)
  end

  def get_tags_frq(id_tag_pair) do
    id_tag_pair
    |> Enum.reduce([], fn {_, tag}, acc -> [tag | acc] end)
    |> List.flatten()
    |> Enum.frequencies()
  end

  def get_tags(id_tag_pair) do
    id_tag_pair
    |> Enum.reduce([], fn {_, tag}, acc -> [tag | acc] end)
    |> List.flatten()
    |> Enum.uniq()
  end

  def get_ids_under_tag(id_tag_pair, query_tag) do
    if query_tag in get_tags(id_tag_pair) do
      Enum.filter(id_tag_pair, fn {_id, tags_in_post} -> query_tag in tags_in_post end)
    else
      []
    end
  end

  # {id, tags} => {tag, id_that_has_this_tag}
  # 未人工验证，Grok 生成
  def get_tags_posts_mapper(id_tag_pair) do
    id_tag_pair
    |> Enum.flat_map(fn {id, tags} ->
      Enum.map(tags, &{&1, id})
    end)
    |> Enum.group_by(fn {tag, _id} -> tag end, fn {_tag, id} -> id end)
    |> Map.new()
  end

  # def get_tags_posts_mapper(id_tag_pair) do
  #   for {id, tags} <- id_tag_pair,
  #       tag <- tags,
  #       into: %{} do
  #     {tag, [id]}
  #   end
  #   |> Map.new(fn {tag, ids} -> {tag, Enum.uniq(ids)} end)
  # end
end
