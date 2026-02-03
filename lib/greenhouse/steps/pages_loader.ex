defmodule Greenhouse.Steps.PagesLoader do
  def as_declarative(opts \\ []), do: {__MODULE__, :page_path_list, :pages_map, opts}

  ## Recipes

  @paths_schema [
    about_location: [
      type: :string,
      default: "about.md",
      doc: ""
    ]
  ]

  # @route_schema [about_route: [type: :string, default: "/about"]]

  def seperate_paths(%Orchid.Param{payload: root_path}, step_options) do
    opts = step_options
    |> Greenhouse.Steps.Helpers.drop_orchid_native()
    |> NimbleOptions.validate!(@paths_schema)

    about_location = Orchid.Param.new(:about_path, :path, Path.join(root_path, opts[:about_location]))

    {:ok, %{about_path: about_location}}
  end

  def load_about(%Orchid.Param{payload: about_path}, _opts) do
    Greenhouse.Params.FileDoc.from_path(about_path)
    |> case do
      doc = %Greenhouse.Params.FileDoc{} -> {:ok, Orchid.Param.new(:about, :doc_struct, doc)}
      error -> error
    end
  end
end
