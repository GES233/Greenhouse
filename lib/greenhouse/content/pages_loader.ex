defmodule Greenhouse.Content.PageLoader do
  def get_page_map(path_map) do
    path_map
    |> Enum.map(fn {op, loc} -> apply(__MODULE__, :"load_#{op}", List.wrap(loc)) end)
    |> Enum.map(fn page -> {page.id, page} end)
    |> Enum.into(%{})
  end

  def load_about(about_path) do
    Greenhouse.Content.FileDoc.from_path(about_path)
    |> case do
      doc = %Greenhouse.Content.FileDoc{} ->
        Greenhouse.Content.Page.from_file_doc(doc)

      error ->
        error
    end
  end

  def load_friends(friends_path) do
    Greenhouse.Content.FileDoc.from_path(friends_path)
    |> case do
      doc = %Greenhouse.Content.FileDoc{} ->
        Greenhouse.Content.Page.from_file_doc(doc)

      error ->
        error
    end
  end
end
