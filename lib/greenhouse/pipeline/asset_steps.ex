defmodule Greenhouse.Pipeline.AssetSteps do
  use Oi.Step, name: :assets

  manifest(
    inputs: [:post_ids],
    outputs: [asset_status: :any]
  )

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

  routine _post_ids, opts do
    validated =
      opts
      |> Keyword.drop([:__orchid_workflow_ctx__, :__reporter_ctx__])
      |> NimbleOptions.validate!(@options_schema)

    source = validated[:source_dir]
    output = validated[:output_dir]

    File.mkdir_p!(Path.dirname(output))

    {_output, 0} =
      System.cmd("mix", ["tailwind", "default", "--input=#{source}", "--output=#{output}"],
        env: [{"MIX_ENV", "dev"}]
      )

    copy_static_assets()

    ok(:ok)
  end

  defp copy_static_assets do
    for file <- ["favicon.ico", "robots.txt"] do
      source = Path.join("source", file)
      target = Path.join("exports", file)
      if File.exists?(source), do: File.copy!(source, target)
    end

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
