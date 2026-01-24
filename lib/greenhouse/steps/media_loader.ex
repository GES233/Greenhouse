defmodule Greenhouse.Steps.MediaLoader do
  use Orchid.Step

  def as_declarative(opts \\ []), do: {__MODULE__, :media_path, [:media_map], opts}

  @opts_schema [
    extensions: [
      type: {:list, :string},
      default: [".png", ".jpg", ".gif"],
      doc: "Allowed media file extensions"
    ],
    recursive: [
      type: :boolean,
      default: true,
      doc: "Whether to scan directories recursively"
    ]
  ]

  def validate_options(step_options) do
    case NimbleOptions.validate(step_options, @opts_schema) do
      {:ok, _validated} -> :ok

      {:error, error} ->
        {:error, Exception.message(error)}
    end
  end

  def run(%Orchid.Param{payload: _media_path}, _step_options) do
    {:ok, Orchid.Param.new(:name, :type, :value)}
  end
end
