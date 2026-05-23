defmodule Greenhouse.Content.Page do
  @type t :: %__MODULE__{
          id: binary(),
          title: binary(),
          route: any(),
          content: binary(),
          doc_struct: struct(),
          extra: map()
        }
  defstruct [:id, :title, :route, :content, :doc_struct, :extra]

  def from_file_doc(file_doc, route) do
    raw = from_file_doc(file_doc)

    %{raw | route: route}
  end

  def from_file_doc(%Greenhouse.Content.FileDoc{
        id: id,
        body: body,
        metadata: content_meta
      }) do
    %__MODULE__{
      id: id,
      content: body,
      title: inject_title(id),
      extra: content_meta[:extra] || %{}
    }
  end

  defp inject_title("about"), do: "关于"
  defp inject_title("friends"), do: "友链"
end
