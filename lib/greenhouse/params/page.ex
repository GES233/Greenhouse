defmodule Greenhouse.Params.Page do
  defstruct [:id, :title, :content, :doc_struct, :extra]

  def from_file_doc(%Greenhouse.Params.FileDoc{
        id: id,
        # created_at: created_at,
        # updated_at: updated_at,
        body: body,
        metadata: _content_meta
      }),
      do: %__MODULE__{
        id: id,
        content: body,
      }
end
