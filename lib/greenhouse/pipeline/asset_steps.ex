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
    {_output, 0} =
      System.cmd("mix", ["tailwind", "default", "--input=#{source}", "--output=#{output}"],
        env: [{"MIX_ENV", "dev"}]
      )

    copy_static_assets()

    {:ok, Orchid.Param.new(:status, :any, :ok)}
  end

  defp copy_static_assets do
    if File.exists?("assets/js") do
      File.mkdir_p!("exports/assets")
      File.cp_r!("assets/js", "exports/assets")
    end

    if File.exists?("assets/vendor") do
      File.mkdir_p!("exports/assets")

      vendor_files = ["fullcalendar.js", "daisyui.js", "daisyui-theme.js", "heroicons.js"]

      Enum.each(vendor_files, fn file ->
        source = Path.join("assets/vendor", file)
        target = Path.join("exports/assets", file)

        if File.exists?(source) do
          File.cp!(source, target)
        end
      end)
    end

    if File.exists?("assets/vendor/pdf_js") do
      File.mkdir_p!("exports/dist")
      File.cp_r!("assets/vendor/pdf_js", "exports/dist/pdf_js")
    end

    if File.exists?("assets/vendor/abcjs") do
      File.mkdir_p!("exports/assets")
      File.cp_r!("assets/vendor/abcjs", "exports/assets/abcjs")
    end
  end
end
