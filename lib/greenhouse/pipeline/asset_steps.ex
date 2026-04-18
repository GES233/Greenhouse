defmodule Greenhouse.Pipeline.AssetSteps do
  use Orchid.Step

  @options_schema [
    source_dir: [
      type: :string,
      default: "assets/css/app.css",
      doc: "Source tailwind file"
    ],
    output_dir: [
      type: :string,
      default: "exports/assets/app.css",
      doc: "Target output file"
    ]
  ]

  def run(_param, step_options) do
    opts =
      step_options
      |> Orchid.Steps.Helpers.drop_orchid_native()
      |> NimbleOptions.validate!(@options_schema)

    source = opts[:source_dir]
    output = opts[:output_dir]

    File.mkdir_p!(Path.dirname(output))

    # Run the tailwind command
    {_output, 0} = System.cmd("mix", ["tailwind", "default", "--input=#{source}", "--output=#{output}"], env: [{"MIX_ENV", "dev"}])

    {:ok, Orchid.Param.new(:status, :any, :ok)}
  end
end
