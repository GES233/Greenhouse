defmodule Greenhouse.Bibliography do
  @moduledoc """
  提供参考文献的支持。

  不同的主体采用不同的格式，默认国标（数字序号）。

  * 国内偏理工农领域（e.g. 毕设） => GB（数字）
  * 国内社科文献较多/社科范式下针对国内的研究对象的讨论 => GB（作者年份）
  # TODO: APA/MLA/IEEE etc.(csl file and scope)

  这里的「国内」指中国大陆，如果以港台相关的文献/对象为主则采用对应地区的推荐格式。
  """

  def to_get_pandoc_meta(%{title: title, extra: extra}, bib_entry) do
    with pandoc_options when map_size(pandoc_options) > 0 <- Map.get(extra, "pandoc", %{}),
         {:ok, bib_path_realtive} <- Map.fetch(pandoc_options, "bibliography"),
         bib_path = Path.join([bib_entry, bib_path_realtive]),
         true <- File.exists?(bib_path) do
      # TODO: Load csl via tag or categories
      # Get csl file via
      # https://www.zotero.org/styles?q=...
      {%{"csl" => Map.get(pandoc_options, "csl", "GB7714")},
       %{
         "bibliography" => bib_path,
         "title" => title
       }}
    else
      # `pandoc` doesn't exist.
      %{} ->
        {%{}, %{}}

      # `bibliography` doesn't exist in pandoc.
      :error ->
        {%{}, %{}}

      # Target file doesn't exist.
      false ->
        {%{}, %{}}
    end
  end
end
