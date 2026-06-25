defmodule Greenhouse.Pipeline.ContentSteps.LoadPosts do
  use Oi.Step, name: :load_posts

  manifest(
    inputs: [:posts_path],
    outputs: [posts_map: :map]
  )

  @posts_opts_schema [
    ignore_markdown: [type: :boolean, default: true, doc: "Ignore *.markdown files"],
    use_git: [type: :boolean, default: false, doc: "Use git commit time as updated date"],
    git_repo: [type: :string, required: false, doc: "Path to git repository (optional)"]
  ]

  routine posts_path, opts do
    with {:ok, validated} <-
           opts
           |> Keyword.drop([:__orchid_workflow_ctx__, :__reporter_ctx__])
           |> NimbleOptions.validate(@posts_opts_schema) do
      git_path =
        if validated[:use_git] do
          validated[:git_repo] || Path.dirname(posts_path)
        else
          nil
        end

      allow_ext = if validated[:ignore_markdown], do: ["md"], else: ~w(md markdown)

      ok(Greenhouse.Content.PostsLoader.posts_path_to_map(posts_path, allow_ext, git_path))
    else
      error -> error
    end
  end
end

defmodule Greenhouse.Pipeline.ContentSteps.LoadPages do
  use Oi.Step, name: :load_pages

  manifest(
    inputs: [:page_root_path],
    outputs: [pages_map: :map]
  )

  @paths_schema [
    about: [type: :string, default: "about.md"],
    friends: [type: :string, default: "friends.md"]
  ]

  routine page_root_path, opts do
    with {:ok, validated} <-
           opts
           |> Keyword.drop([:__orchid_workflow_ctx__, :__reporter_ctx__])
           |> NimbleOptions.validate(@paths_schema) do
      page_map = %{
        about: Path.join(page_root_path, validated[:about]),
        friends: Path.join(page_root_path, validated[:friends])
      }

      ok(Greenhouse.Content.PageLoader.get_page_map(page_map))
    else
      error -> error
    end
  end
end

defmodule Greenhouse.Pipeline.ContentSteps.ReplaceLink do
  use Oi.Step, name: :replace_link

  manifest(
    inputs: [:posts_map, :pages_map, :media_map],
    outputs: [replaced_posts_map: :map, replaced_pages_map: :map]
  )

  routine [posts_map, pages_map, media_map], _opts do
    {updated_posts_map, updated_pages_map} =
      Greenhouse.Cite.ContentReplacer.replace_posts(posts_map, pages_map, media_map)

    ok({updated_posts_map, updated_pages_map})
  end
end
