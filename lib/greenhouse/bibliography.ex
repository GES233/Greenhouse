defmodule Greenhouse.Bibliography do
  def to_get_pandoc_meta(%{title: title, extra: extra}, bib_entry) do
    with pandoc_options when map_size(pandoc_options) > 0 <- Map.get(extra, "pandoc", %{}),
         {:ok, bib_path_realtive} <- Map.fetch(pandoc_options, "bibliography"),
         bib_path = Path.join([bib_entry, bib_path_realtive]),
         true <- File.exists?(bib_path) do
      %{
        "bibliography" => bib_path,
        "csl" => Map.get(pandoc_options, "csl") || "GB7714",
        "title" => title
      }
    else
      # `pandoc` doesn't exist.
      %{} ->
        %{}

      # `bibliography` doesn't exist in pandoc.
      :error ->
        %{}

      # Target file doesn't exist.
      false ->
        %{}
    end
  end
end
