defmodule Greenhouse.Media.MediaLoader do
  alias Greenhouse.Media.MediaLoader.InnerRecipe, as: S

  @spec as_declarative(generated_root_target :: Path.t() | nil) :: Orchid.Step.t()
  def as_declarative(generated_root_target \\ nil) do
    inner_steps = [
      {&S.load_images/2, :pic_path, :pic_map, generated_root_target: generated_root_target},
      {&S.load_pdfs/2, :pdf_path, :pdf_map, generated_root_target: generated_root_target},
      {&S.load_dots/2, :dot_path, :svg_map, generated_root_target: generated_root_target},
      # TODO: Add Lilyond(optional)
      {&S.merger/2, [:pic_map, :svg_map, :pdf_map], :media_map}
    ]

    {
      Orchid.Step.NestedStep,
      [:pic_path, :dot_path, :pdf_path],
      :media_map,
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

defmodule Greenhouse.Media.MediaLoader.InnerMacro do
  alias Greenhouse.Asset.Media
  alias Greenhouse.Media.MediaLoader

  defmacro def_media_loader(func_name, extensions, media_type, out_key) do
    quote do
      def unquote(func_name)(%Orchid.Param{payload: root_path}, opts) do
        media_operator =
          Keyword.get(opts, :generated_root_target, nil)
          |> case do
            nil -> &Media.path_to_media(&1, unquote(media_type))
            path when is_binary(path) -> &Media.path_to_media(&1, unquote(media_type))
          end

        root_path
        |> MediaLoader.wildcard(unquote(extensions))
        |> Task.async_stream(media_operator)
        |> Enum.map(fn {:ok, media} -> {media.id, media} end)
        |> then(&Orchid.Param.new(unquote(out_key), :map, &1))
        |> then(&{:ok, &1})
      end
    end
  end
end

defmodule Greenhouse.Media.MediaLoader.InnerRecipe do
  alias Greenhouse.Asset.Media
  import Greenhouse.Media.MediaLoader.InnerMacro

  @doc """
  ### Examples

      Orchid.run(
        Orchid.Recipe.new(
          [
            {&Greenhouse.Media.MediaLoader.InnerRecipe.load_images/2, :img_root, :img_map}
          ]
        ),
        [
          Orchid.Param.new(:img_root, :path, "D:/Blog/source/img")
        ]
      )
  """
  def_media_loader(:load_images, ~w(png jpg jpeg gif), Media.Picture, :image_maps)

  @doc """
  ### Examples

      Orchid.run(
        Orchid.Recipe.new(
          [
            {&Greenhouse.Media.MediaLoader.InnerRecipe.load_pdfs/2, :pdf_root, :pdf_map}
          ]
        ),
        [
          Orchid.Param.new(:pdf_root, :path, "D:/Blog/source/pdf")
        ]
      )
  """
  def_media_loader(:load_pdfs, ~w(pdf), Media.PDF, :pdf_maps)

  def_media_loader(:load_dots, ~w(dot), Media.Graphviz, :dot_maps)

  def merger(media_map, _opts) do
    media_map
    |> Enum.map(& &1.payload)
    |> List.flatten()
    |> Enum.into(%{})
    |> then(&Orchid.Param.new(:media_map, :map, &1))
    |> then(&{:ok, &1})
  end
end
