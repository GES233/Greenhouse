defmodule Greenhouse.Media.MediaLoader do
  @moduledoc "Media loading utilities."

  def wildcard(root, ext) do
    ext_part =
      case ext do
        [single] -> single
        _ -> "{#{Enum.join(ext, ",")}}"
      end

    Path.wildcard("#{root}/**/*.#{ext_part}")
  end
end

defmodule Greenhouse.Media.LoadImages do
  use Oi.Step, name: :load_images
  alias Greenhouse.Asset.Media

  manifest(
    inputs: [:pic_path],
    outputs: [pic_map: :map]
  )

  routine pic_path, _opts do
    pic_path
    |> Greenhouse.Media.MediaLoader.wildcard(~w(png jpg jpeg gif))
    |> Task.async_stream(&Media.path_to_media(&1, Media.Picture))
    |> Enum.map(fn {:ok, media} -> {media.id, media} end)
    |> Enum.into(%{})
    |> then(&ok(&1))
  end
end

defmodule Greenhouse.Media.LoadPdfs do
  use Oi.Step, name: :load_pdfs
  alias Greenhouse.Asset.Media

  manifest(
    inputs: [:pdf_path],
    outputs: [pdf_map: :map]
  )

  routine pdf_path, _opts do
    pdf_path
    |> Greenhouse.Media.MediaLoader.wildcard(~w(pdf))
    |> Task.async_stream(&Media.path_to_media(&1, Media.PDF))
    |> Enum.map(fn {:ok, media} -> {media.id, media} end)
    |> Enum.into(%{})
    |> then(&ok(&1))
  end
end

defmodule Greenhouse.Media.LoadDots do
  use Oi.Step, name: :load_dots
  alias Greenhouse.Asset.Media

  manifest(
    inputs: [:dot_path],
    outputs: [svg_map: :map]
  )

  routine dot_path, _opts do
    dot_path
    |> Greenhouse.Media.MediaLoader.wildcard(~w(dot))
    |> Task.async_stream(&Media.path_to_media(&1, Media.Graphviz))
    |> Enum.map(fn {:ok, media} -> {media.id, media} end)
    |> Enum.into(%{})
    |> then(&ok(&1))
  end
end

defmodule Greenhouse.Media.MergeMedia do
  use Oi.Step, name: :merge_media

  manifest(
    inputs: [:pic_map, :svg_map, :pdf_map],
    outputs: [media_map: :map]
  )

  routine [pic_map, svg_map, pdf_map], _opts do
    [pic_map, svg_map, pdf_map]
    |> Enum.reduce(%{}, fn map, acc -> Map.merge(acc, map) end)
    |> then(&ok(&1))
  end
end
