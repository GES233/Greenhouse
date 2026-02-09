defmodule Greenhouse.Pipeline.ContentSteps do
  import Orchid.Steps.Helpers
  require Orchid.ParamFactory

  ## Load Posts

  @posts_opts_schema [
    ignore_markdown: [
      type: :boolean,
      default: true,
      doc: "Ignore *.markdown files"
    ],
    use_git: [
      type: :boolean,
      default: false,
      doc: "Use git commit time as updated date"
    ],
    git_repo: [
      type: :string,
      required: false,
      doc: "Path to git repository (optional)"
    ]
  ]

  @doc """
  ## Options

  * `:ignore_markdown` (Boolean) - Ignore `*.markdown`, default as true.
  * `:use_git` (Boolean) - If true, return updated date by git commit.
  * `:git_repo` (Optional(Binary))
  """
  def load_posts(%Orchid.Param{payload: post_root_path}, step_options) do
    with {:ok, opts} <-
           step_options
           |> drop_orchid_native()
           |> NimbleOptions.validate(@posts_opts_schema) do
      git_path =
        if opts[:use_git] do
          opts[:git_repo] || Path.dirname(post_root_path)
        else
          nil
        end

      allow_ext =
        if opts[:ignore_markdown],
          do: ["md"],
          else: ~w(md markdown)

      {:ok,
       Orchid.Param.new(
         :posts_map,
         :map,
         Greenhouse.Content.PostsLoader.posts_path_to_map(post_root_path, allow_ext, git_path)
       )}
    else
      error -> error
    end
  end

  ## Page Loader

  @paths_schema [
    about: [
      type: :string,
      default: "about.md",
      doc: ""
    ]
    # friends: [
    #   type: :string,
    #   default: "friends.md",
    #   doc: ""
    # ]
  ]

  def load_pages(root_path, step_options) do
    with %{} = page_map <- seperate_paths(root_path, step_options) do
      {:ok,
       page_map
       |> Greenhouse.Content.PageLoader.get_page_map()
       |> then(&Orchid.Param.new(:pages_map, :map, &1))}
    else
      error -> error
    end
  end

  def seperate_paths(%Orchid.Param{payload: root_path}, step_options) do
    case step_options
         |> Orchid.Steps.Helpers.drop_orchid_native()
         |> NimbleOptions.validate(@paths_schema) do
      {:ok, opts} ->
        about_location = Path.join(root_path, opts[:about])
        # friends_location = Path.join(root_path, opts[:friends])

        %{about: about_location}

      error ->
        error
    end
  end

  ## Replace Content's Link

  def replace_link([posts_map, pages_map, media_map], _step_options) do
    {updated_posts_map, updated_pages_map} =
      Greenhouse.Cite.ContentReplacer.replace_posts(
        Orchid.Param.get_payload(posts_map),
        Orchid.Param.get_payload(pages_map),
        Orchid.Param.get_payload(media_map)
      )

    {:ok,
     [
       Orchid.ParamFactory.to_param(updated_posts_map, :map),
       Orchid.ParamFactory.to_param(updated_pages_map, :map)
     ]}
  end
end
