defmodule Greenhouse.Steps.PagesLoader do
  @spec as_declarative(keyword()) :: Orchid.Step.t()
  def as_declarative(opts \\ []), do: {__MODULE__, :page_root_path, :pages_map, opts}

  use Orchid.Step

  def run(root_path, step_options) do
    {:ok,
     seperate_paths(root_path, step_options)
     |> Enum.map(fn {op, loc} -> apply(__MODULE__, op, List.wrap(loc)) end)
     |> Enum.map(fn page -> {page.id, page} end)
     |> Enum.into(%{})
     |> then(&Orchid.Param.new(:pages_map, :map, &1))}
  end

  @paths_schema [
    about_location: [
      type: :string,
      default: "about.md",
      doc: ""
    ]
    # friends_location: [
    #   type: :string,
    #   default: "friends.md",
    #   doc: ""
    # ]
  ]

  def seperate_paths(%Orchid.Param{payload: root_path}, step_options) do
    opts =
      step_options
      |> Greenhouse.Steps.Helpers.drop_orchid_native()
      |> NimbleOptions.validate!(@paths_schema)

    about_location = Path.join(root_path, opts[:about_location])
    # friends_location = Path.join(root_path, opts[:friends_location])

    %{load_about: about_location}
  end

  def load_about(about_path) do
    Greenhouse.Params.FileDoc.from_path(about_path)
    |> case do
      doc = %Greenhouse.Params.FileDoc{} ->
        Greenhouse.Params.Page.from_file_doc(doc)

      error ->
        error
    end
  end

  def load_friends(friends_path) do
    Greenhouse.Params.FileDoc.from_path(friends_path)
    |> case do
      doc = %Greenhouse.Params.FileDoc{} ->
        Greenhouse.Params.Page.from_file_doc(doc)

      error ->
        error
    end
  end
end
