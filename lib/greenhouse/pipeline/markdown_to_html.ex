defmodule Greenhouse.Steps.MarkdownToHTML do
  use Oi.Step, name: :markdown_to_html
  require Logger

  manifest(
    inputs: [:content_map, :bib_entry],
    outputs: [with_doc_struct: :map]
  )

  routine [content_map, bib_entry_path], _opts do
    content_map
    |> Task.async_stream(
      fn {_id, p} -> convert_to_markdown(p, bib_entry_path) end,
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
      [_ | _] = list ->
        list
        |> Enum.map(fn p -> {p.id, p} end)
        |> Enum.into(%{})
        |> then(&ok(&1))

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
