defmodule Greenhouse.Steps.MarkdownToHTML do
  require Logger
  use Orchid.Step

  def run([posts_map_or_pages_map, bib_entry], _step_options) do
    bib_entry_path = Orchid.Param.get_payload(bib_entry)

    posts_map_or_pages_map
    |> Orchid.Param.get_payload()
    |> Task.async_stream(
      fn {_id, p} -> convert_to_markdown(p, bib_entry_path) end,
      # TODO: Add option
      max_concurrency: System.schedulers_online(),
      timeout: :infinity
    )
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
          |> Greenhouse.Bibliography.to_get_pandoc_meta(bib_entry)
          |> then(&Pandox.render_markdown_to_html(post_or_page.content, &1))
    }
  end
end
