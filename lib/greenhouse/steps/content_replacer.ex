defmodule Greenhouse.Steps.ContentReplacer do
  use Orchid.Step
  alias Greenhouse.Params.Link

  @replaced_pattern ~r/:\{(\S+)\}/

  def run([posts_map, pages_map, media_map], _step_options) do
    replace_posts(
      Orchid.Param.get_payload(posts_map),
      Orchid.Param.get_payload(pages_map),
      Orchid.Param.get_payload(media_map)
    )

    {:ok, Orchid.Param.new(:for, :name)}
  end

  def replace_posts(posts_map, pages_map, media_map) do
    maybe_resource_map =
      Map.merge(pages_map, media_map)
      |> Map.merge(posts_map)

    updated_posts_map = Enum.map(posts_map, &replace_single(&1, maybe_resource_map))
    updated_pages_map = Enum.map(pages_map, &replace_single(&1, maybe_resource_map))

    {updated_posts_map, updated_pages_map}
  end

  defp replace_single({key, %{content: content} = post_or_post}, maybe_resource_map) do
    query_func = fn cought ->
      k =
        Regex.run(@replaced_pattern, cought)
        |> Enum.at(1)

      Link.convert(maybe_resource_map[k])
    end

    {key,
     %{
       post_or_post
       | content: String.replace(content, @replaced_pattern, query_func)
     }}
  end
end
