defmodule Greenhouse.Params.Post do
  @type t :: %__MODULE__{
          id: binary(),
          title: binary(),
          created_at: DateTime.t() | Date.t(),
          updated_at: DateTime.t() | Date.t(),
          index_view: %{
            tags: [binary()],
            series: binary() | nil,
            categories: any()
          },
          content: binary(),
          doc_struct: struct(),
          # | [:wip, non_neg_integer()] | [:block, non_neg_integer()],
          progress: :final,
          extra: %{}
        }
  defstruct [
    :id,
    :title,
    :created_at,
    :updated_at,
    :index_view,
    :content,
    :doc_struct,
    progress: :final,
    extra: %{}
  ]

  def from_file_doc(
        %Greenhouse.Params.FileDoc{
          id: id,
          created_at: created_at,
          updated_at: updated_at,
          body: body,
          metadata: content_meta
        },
        repo_path \\ nil,
        ext \\ "md"
      ) do
    title = content_meta[:title]
    categories = content_meta[:categories]
    tags = (content_meta[:tags] || []) |> :lists.flatten()
    series = content_meta[:series]
    progress = content_meta[:progress] || :final

    updated_date =
      if !is_nil(repo_path) do
        overwrite_update(id, updated_at, repo_path, ext)
      else
        updated_at |> convert_date()
      end

    %__MODULE__{
      id: id,
      created_at: overwrite_create(created_at, content_meta),
      updated_at: updated_date,
      title: title,
      content: body,
      index_view: %{
        tags: tags,
        categories: categories,
        series: series
      },
      progress: progress,
      # Map.reject(content_meta, fn {k, _} -> k in [] end)
      extra: content_meta[:extra] || %{}
    }
  end

  defp overwrite_create(oldcreated_at, content_meta) do
    maybe_create_from_file = content_meta[:create_at] || content_meta[:date] || oldcreated_at

    convert_date(maybe_create_from_file)
  end

  defp overwrite_update(id, file_update, repo_path, ext) do
    Git.execute_command(
      %Git.Repository{path: repo_path},
      "log",
      ~w(--pretty=format:\"%cd\" --date=iso-strict -1 _posts/#{id}.#{ext}),
      fn date_string ->
        date_string
        |> String.replace(~r("), "")
        |> DateTime.from_iso8601()
        |> case do
          # Uncommit file.
          {:ok, commit_time, _} -> {:ok, commit_time}
          _ -> {:ok, DateTime.now!("Asia/Shanghai")}
        end
      end
    )
    |> case do
      {:ok, datetime} -> convert_date(datetime)
      {:error, _} -> convert_date(file_update)
    end
  end

  defp convert_date(%DateTime{} = datetime), do: datetime

  defp convert_date(datetime) when is_tuple(datetime) do
    NaiveDateTime.from_erl!(datetime)
  end

  defp convert_date(datetime) when is_binary(datetime) do
    NaiveDateTime.from_iso8601!(datetime)
  end
end
