defmodule Pandox do
  @moduledoc """
  Documentation for `Pandox`.
  """

  require Logger

  @pandoc_executable_name System.find_executable("pandoc") || "pandoc"

  def get_pandoc() do
    @pandoc_executable_name
  end

  def get_args_from_meta(%{"pandoc" => args}), do: do_extract_args(args)
  def get_args_from_meta(%{pandoc: args}), do: do_extract_args(args)
  def get_args_from_meta(_), do: []

  def do_extract_args(meta), do: meta

  @pandoc_flags ~w(
    --mathjax
    -f markdown+smart+emoji
    -t html
  )

  @pandoc_crossref_flags ~w(
    --filter=pandoc-crossref
    --citeproc
  )

  def render_markdown_to_html(content, {metadata, metadata_to_pandoc}, _opts \\ []) do
    input_file = Path.join(System.tmp_dir!(), "input_#{System.unique_integer()}.md")
    output_file = Path.join(System.tmp_dir!(), "output_#{System.unique_integer()}.html")

    csl = Map.get(metadata, "csl", "GB7714")
    File.write!(input_file, build_front_matter(metadata_to_pandoc) <> "\n" <> content)

    res =
      args(input_file, output_file, csl)
      # |> IO.inspect(label: :Args)
      |> Enum.join(" ")
      |> then(&System.shell("#{get_pandoc()} #{&1}"))
      |> handle_result(output_file)

    File.rm(input_file)
    File.rm(output_file)

    res
  end

  def args(input, output, csl) do
    yaml_path = "priv/pandoc_cressref.yaml" |> Path.absname()
    yaml = "-M crossrefYaml=\"" <> yaml_path <> "\""

    csl_path =
      ("priv/csl/" <> csl <> ".csl")
      |> Path.absname()

    csl = "--csl=\"" <> csl_path <> "\""

    lua_root_path = "priv/lua_filters/structure.lua" |> Path.absname()
    lua_filter = ["--lua-filter=\"" <> lua_root_path <> "\""]

    parse_flag =
      ~w(
          --toc
          --template
          #{Path.absname("priv/template/structural.html")}
        )

    @pandoc_flags ++
      @pandoc_crossref_flags ++ lua_filter ++ parse_flag ++ [yaml, csl, input, "-o", output]
  end

  defp build_front_matter(metadata) when map_size(metadata) < 1, do: ""

  defp build_front_matter(metadata) do
    res =
      metadata
      |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
      |> Enum.join("\n")

    """
    ---
    #{res}
    ---
    """
  end

  defp handle_result({_, 0}, output_file) do
    output_file |> File.read!() |> String.replace("\r\n", "\n") |> parse_pandoc_output()
  end

  defp handle_result({msg, code}, _) do
    Logger.error("Pandoc failed with code #{code}: #{msg}")

    :error
  end

  ## == Postlude ==

  defmodule Doc do
    @type t :: %__MODULE__{
            body: binary(),
            toc: binary() | nil,
            summary: binary() | nil,
            bibliography: binary() | nil,
            footnotes: binary() | nil,
            meta: term()
          }
    defstruct [:body, :toc, :summary, :bibliography, :footnotes, :meta]
  end

  defp parse_pandoc_output(raw_output) do
    extract = fn section_name ->
      regex = ~r/<!--SECTION_START:#{section_name}-->(.*?)<!--SECTION_END:#{section_name}-->/s

      case Regex.run(regex, raw_output) do
        [_, content] -> String.trim(content)
        nil -> nil
      end
    end

    %Doc{
      body: extract.("BODY"),
      toc: extract.("TOC"),
      summary: extract.("SUMMARY"),
      bibliography: extract.("BIB"),
      footnotes: extract.("NOTES"),
      # TODO: add Jason to parse json part
      meta: extract.("META")
    }
  end
end

defimpl Inspect, for: Pandox.Doc do
  import Inspect.Algebra

  def inspect(doc, opts) do
    payload = [
      body: format_long_text(doc.body),
      toc: format_long_text(doc.toc),
      summary: format_long_text(doc.summary),
      bibliography: format_long_text(doc.bibliography),
      footnotes: format_long_text(doc.footnotes),
      meta: format_long_text(doc.meta)
    ]

    # 最终输出形如 #Pandox.Doc<[body: "...", ...]>
    concat(["#Pandox.Doc<", to_doc(payload, opts), ">"])
  end

  defp format_long_text(nil), do: nil

  defp format_long_text(text) when is_binary(text) do
    limit = 100
    size = byte_size(text)

    if size > limit do
      prefix = String.slice(text, 0, limit)

      clean_prefix = String.replace(prefix, ~r/\R/, " ")

      "#{clean_prefix} ... <> (total #{size} bytes)"
    else
      text
    end
  end

  defp format_long_text(other), do: other
end
