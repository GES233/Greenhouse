defmodule Pandox do
  @moduledoc """
  Documentation for `Pandox`.
  """
  require Logger

  # 默认的 pandoc 可执行文件的地址
  # （我假定你是通过 Scoop/apt/Homebrew 等方式安装的）
  @pandoc_executable_name System.find_executable("pandoc") || "pandoc"

  def get_pandoc() do
    # 还要考虑从配置中读取可执行文件的地址的情况
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

  def render_markdown_to_html(content, metadata_to_pandoc, _opts \\ []) do
    # 生成临时文件
    input_file = Path.join(System.tmp_dir!(), "input_#{System.unique_integer()}.md")
    output_file = Path.join(System.tmp_dir!(), "output_#{System.unique_integer()}.html")

    # 写入内容（包含元数据）
    File.write!(input_file, build_front_matter(metadata_to_pandoc) <> "\n" <> content)

    # 调用 Pandoc
    res =
      args(input_file, output_file)
      # |> IO.inspect(label: :Args)
      # 使用 System.cmd 会报错
      # |> then(&System.cmd(get_pandoc(), &1))
      |> Enum.join(" ")
      |> then(&System.shell("#{get_pandoc()} #{&1}"))
      |> handle_result(output_file)

    File.rm(input_file)
    File.rm(output_file)

    res
  end

  def args(input, output) do
    yaml_path = "priv/pandoc_cressref.yaml" |> Path.absname()
    yaml = "-M crossrefYaml=\"" <> yaml_path <> "\""

    csl_path = "priv/csl/GB7714.csl" |> Path.absname()
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
    # 使用正则或字符串分割提取各个部分
    # 这里写一个通用的提取器
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
    # 构造一个展示用的 Keyword List
    # 这样可以保证 inspect 输出的顺序整洁
    payload = [
      body: format_long_text(doc.body),
      toc: format_long_text(doc.toc),
      summary: format_long_text(doc.summary),
      bibliography: format_long_text(doc.bibliography),
      footnotes: format_long_text(doc.footnotes),
      meta: format_long_text(doc.meta)
    ]

    # 使用 Inspect.Algebra 拼接文档
    # 最终输出形如: #Pandox.Doc<[body: "...", ...]>
    concat(["#Pandox.Doc<", to_doc(payload, opts), ">"])
  end

  # 处理 nil 的情况
  defp format_long_text(nil), do: nil

  # 处理二进制字符串的情况
  defp format_long_text(text) when is_binary(text) do
    limit = 100
    size = byte_size(text)

    if size > limit do
      # 1. 截取前 100 个字符 (使用 String.slice 避免切断 UTF-8 多字节字符)
      # 虽然题目要求 100 bytes，但在 Elixir 中截断显示通常按字符更安全
      prefix = String.slice(text, 0, limit)

      # 2. 移除换行符，避免日志刷屏，保持紧凑
      # 如果你希望保留换行结构，可以去掉这行
      clean_prefix = String.replace(prefix, ~r/\R/, " ")

      # 3. 构造截断提示字符串
      # 注意：这里返回的是一个字符串，最终 Inspect 会加上双引号显示它
      "#{clean_prefix} ... <> (total #{size} bytes)"
    else
      text
    end
  end

  # 兜底情况（虽然理论上 struct 定义里这些字段应当是 binary 或 nil）
  defp format_long_text(other), do: other
end
