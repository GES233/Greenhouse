defmodule Greenhouse.Params.Page do
  defstruct [:id, :title, :content, :doc_struct, :extra]

  def from_file_doc(%Greenhouse.Params.FileDoc{
        id: id,
        body: body,
        metadata: content_meta
      }),
      do: %__MODULE__{
        id: id,
        content: body,
        extra: content_meta[:extra]
      }
end
