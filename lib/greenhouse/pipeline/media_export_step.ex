defmodule Greenhouse.Pipeline.MediaExportStep do
  use Oi.Step, name: :media_export
  alias Greenhouse.Asset.Media

  manifest(
    inputs: [:media_map],
    outputs: [media_export_status: :any]
  )

  @options_schema [
    output_dir: [
      type: :string,
      default: "exports",
      doc: "Directory to write output files"
    ]
  ]

  routine media_map, opts do
    validated =
      opts
      |> Keyword.drop([:__orchid_workflow_ctx__, :__reporter_ctx__])
      |> NimbleOptions.validate!(@options_schema)

    output_dir = validated[:output_dir]

    media_map
    |> Map.values()
    |> Task.async_stream(fn media ->
      Media.operate_media(media, output_dir)
    end)
    |> Enum.to_list()

    ok(:ok)
  end
end
