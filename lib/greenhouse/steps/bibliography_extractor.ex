defmodule Greenhouse.Steps.HTMLConvertorWithBibliography do
  require Logger
  use Orchid.Step

  def process_posts_as_declarative(_opts \\ []),
    do: {__MODULE__, [:replaced_posts_map, :bib_entry], :posts_map_with_doc_struct}

  def process_pages_as_declarative(_opts \\ []),
    do: {__MODULE__, [:replaced_pages_map, :bib_entry], :pages_map_with_doc_struct}

  def run([posts_map_or_pages_map, bib_entry], _step_options) do
    bib_entry_path = Orchid.Param.get_payload(bib_entry)

    posts_map_or_pages_map
    |> Orchid.Param.get_payload()
    |> Task.async_stream(fn {_id, p} -> convert_to_markdown(p, bib_entry_path)end)
    |> Enum.reduce_while([], fn {state, payload}, acc ->
      case state do
        :ok -> {:cont, [payload | acc]}
        _ -> {:halt, {:error, acc}}
      end
    end)
    |> case do
      [_ | _] = posts_map_or_pages_list ->
        Enum.map(posts_map_or_pages_list, fn p -> {p.id, p} end)
        |> Enum.into(%{})
        |> then(&{:ok, Orchid.Param.new(:with_doc_struct, :map, &1)})

      err ->
        err
    end
  end

  def convert_to_markdown(post_or_page, bib_entry) do
    %{
      post_or_page
      | doc_struct:
          post_or_page
          |> validate_bibliography_and_get_pandoc_meta(bib_entry)
          |> then(&Pandox.render_markdown_to_html(post_or_page.content, &1))
    }
  end

  def validate_bibliography_and_get_pandoc_meta(%{title: title, extra: extra}, bib_entry) do
    with pandoc_options when map_size(pandoc_options) > 0 <- Map.get(extra, "pandoc", %{}),
         {:ok, bib_path_realtive} <- Map.fetch(pandoc_options, "bibliography"),
         bib_path = Path.join([bib_entry, bib_path_realtive]),
         true <- File.exists?(bib_path) do
      %{
        "bibliography" => bib_path,
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
