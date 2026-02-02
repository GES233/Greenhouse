defmodule Greenhouse.Steps.MediaLoader do
  alias Greenhouse.Steps.MediaLoader.InnerRecipe, as: S

  def as_declarative(generated_root_target \\ nil) do

    inner_steps = [
      {&S.load_images/2, :pic_path, :pic_map, generated_root_target: generated_root_target},
      {&S.load_pdfs/2, :pdf_path, :pdf_map, generated_root_target: generated_root_target},
      {&S.load_dots/2, :dot_path, :svg_map, generated_root_target: generated_root_target},
      # TODO: Add Lilyond(optional)
      {&S.merger/2, [:pic_map, :svg_map, :pdf_map], :media_map},
    ]

    {
      Orchid.Step.NestedStep, [:pic_path, :dot_path, :pdf_path], :media_map,
      # There're some bug in private funtion align_output_names/2 in Orchid.Runner.Hooks.Core
      output_map: %{media_map: :media_map},
      recipe: Orchid.Recipe.new(inner_steps)
    }
  end

  def wildcard(root, ext) do
    ext_part =
      case ext do
        [single] -> single
        _ -> "{#{Enum.join(ext, ",")}}"
      end

    Path.wildcard("#{root}/**/*.#{ext_part}")
  end
end

defmodule Greenhouse.Steps.MediaLoader.InnerRecipe do
  alias Greenhouse.Params.Media
  alias Greenhouse.Steps.MediaLoader

  @doc """
  ### Examples

      Orchid.run(
        Orchid.Recipe.new(
          [
            {&Greenhouse.Steps.MediaLoader.InnerRecipe.load_images/2, :img_root, :img_map}
          ]
        ),
        [
          Orchid.Param.new(:img_root, :path, "D:/Blog/source/img")
        ]
      )
  """
  def load_images(%Orchid.Param{payload: img_root}, opts) do
    media_operator =
      Keyword.get(opts, :generated_root_target, nil)
      |> case do
        nil -> &Media.path_to_media(&1, Media.Picture)
        path when is_binary(path) -> &Media.path_to_media(&1, path, Media.Picture)
      end

    img_root
    |> MediaLoader.wildcard(~w(png jpg jpeg gif))
    |> Task.async_stream(media_operator)
    |> Enum.map(fn {:ok, media} -> {media.id, media} end)
    |> then(&Orchid.Param.new(:image_maps, :map, &1))
    |> then(&{:ok, &1})
  end

  @doc """
  ### Examples

      Orchid.run(
        Orchid.Recipe.new(
          [
            {&Greenhouse.Steps.MediaLoader.InnerRecipe.load_pdfs/2, :pdf_root, :pdf_map}
          ]
        ),
        [
          Orchid.Param.new(:pdf_root, :path, "D:/Blog/source/pdf")
        ]
      )
  """
  def load_pdfs(%Orchid.Param{payload: pdf_root}, opts) do
    media_operator =
      Keyword.get(opts, :generated_root_target, nil)
      |> case do
        nil -> &Media.path_to_media(&1, Media.PDF)
        path when is_binary(path) -> &Media.path_to_media(&1, path, Media.PDF)
      end

    pdf_root
    |> MediaLoader.wildcard(~w(pdf))
    |> Task.async_stream(media_operator)
    |> Enum.map(fn {:ok, media} -> {media.id, media} end)
    |> then(&Orchid.Param.new(:pdf_maps, :map, &1))
    |> then(&{:ok, &1})
  end

  def load_dots(%Orchid.Param{payload: dot_root}, opts) do
    media_operator =
      Keyword.get(opts, :generated_root_target, nil)
      |> case do
        nil -> &Media.path_to_media(&1, Media.Graphviz)
        path when is_binary(path) -> &Media.path_to_media(&1, path, Media.Graphviz)
      end

    dot_root
    |> MediaLoader.wildcard(~w(dot))
    |> Task.async_stream(media_operator)
    |> Enum.map(fn {:ok, media} -> {media.id, media} end)
    |> then(&Orchid.Param.new(:dot_maps, :map, &1))
    |> then(&{:ok, &1})
  end

  def merger(media_map, _opts) do
    media_map
    |> Enum.map(&(&1.payload))
    |> List.flatten()
    |> Enum.into(%{})
    |> then(&Orchid.Param.new(:media_map, :map, &1))
    |> then(&{:ok, &1})
  end
end
