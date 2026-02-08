defmodule Greenhouse.Content.Page do
  defstruct [:id, :title, :route, :content, :doc_struct, :extra]

  def from_file_doc(file_doc, route) do
    raw = from_file_doc(file_doc)

    %{raw | route: route}
  end

  def from_file_doc(%Greenhouse.Content.FileDoc{
        id: id,
        body: body,
        metadata: content_meta
      }),
      do: %__MODULE__{
        id: id,
        content: body,
        extra: content_meta[:extra] || %{}
      }
end
