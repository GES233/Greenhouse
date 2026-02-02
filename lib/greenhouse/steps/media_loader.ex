defmodule Greenhouse.Steps.MediaLoader do
  use Orchid.Step
  import Greenhouse.Steps.Helpers

  def as_declarative(opts \\ []),
    do: {__MODULE__, [:pic_path, :dot_path, :pdf_path], [:media_map], opts}

  @opts_schema [
    pic_extensions: [
      type: {:list, :string},
      default: [".png", ".jpg", ".gif"],
      doc: "Allowed picture file extensions"
    ],
    dot_extensions: [
      type: {:list, :string},
      default: [".dot"],
      doc: "Allowed dot file extensions"
    ],
    doc_extensions: [
      type: {:list, :string},
      default: [".pdf"],
      doc: "Allowed document file extensions"
    ],
    recursive: [
      type: :boolean,
      default: true,
      doc: "Whether to scan directories recursively"
    ]
  ]

  def validate_options(step_options) do
    case NimbleOptions.validate(drop_orchid_native(step_options), @opts_schema) do
      {:ok, _validated} ->
        :ok

      {:error, error} ->
        {:error, Exception.message(error)}
    end
  end

  def run(%Orchid.Param{payload: _media_path}, _step_options) do
    {:ok, Orchid.Param.new(:name, :type, :value)}
  end

  def wildcard(root, ext) do
    ext_part = case ext do
      [single] -> single
      _ -> "{#{Enum.join(ext, ",")}}"
    end

    Path.wildcard("#{root}/**/#{ext_part}")
  end
end
