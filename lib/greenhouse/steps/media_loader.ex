defmodule Greenhouse.Steps.MediaLoader do
  alias Greenhouse.Steps.MediaLoader.InnerRecipe, as: S

  def as_declarative(_opts \\ []) do
    inner_steps = [
      {&S.load_images/2, :pic_path, :pic_map},
      {&S.load_pdfs/2, :pdf_path, :pdf_map},
    ]

    {Orchid.Step.NestedStep, [:pic_path, :pdf_path], [:media_map],
     recipe: Orchid.Recipe.new(inner_steps)}
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
end
