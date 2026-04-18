defmodule Greenhouse.Pipeline.MediaExportStep do
  use Orchid.Step
  alias Greenhouse.Asset.Media

  @options_schema [
    output_dir: [
      type: :string,
      default: "exports",
      doc: "Directory to write output files"
    ]
  ]

  def run(%Orchid.Param{payload: media_map}, step_options) do
    opts =
      step_options
      |> Orchid.Steps.Helpers.drop_orchid_native()
      |> NimbleOptions.validate!(@options_schema)

    output_dir = opts[:output_dir]

    media_map
    |> Map.values()
    |> Task.async_stream(fn media ->
      Media.operate_media(media, output_dir)
    end)
    |> Enum.to_list()

    {:ok, Orchid.Param.new(:media_export_status, :any, :ok)}
  end
end
