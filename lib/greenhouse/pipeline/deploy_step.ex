defmodule Greenhouse.Pipeline.DeployStep do
  use Oi.Step, name: :deploy
  require Logger

  manifest(
    inputs: [:asset_status],
    outputs: [deploy_status: :any]
  )

  @options_schema [
    git_url: [
      type: :string,
      required: true,
      doc: "The remote git repository URL to deploy to"
    ],
    git_branch: [
      type: :string,
      default: "site",
      doc: "The branch to deploy the built files to"
    ],
    output_dir: [
      type: :string,
      default: "exports",
      doc: "The directory containing the built files to deploy"
    ],
    deploy_dir: [
      type: :string,
      default: ".deploy_git",
      doc: "The temporary local directory used for the deployment repository"
    ],
    commit_message: [
      type: {:or, [:string, nil]},
      default: nil,
      doc: "The commit message to use. If nil, defaults to 'Site updated on YYYY-MM-DD HH:MM:SS'"
    ],
    push: [
      type: :boolean,
      default: false,
      doc: "Whether to actually push to the remote repository"
    ]
  ]

  routine _asset_status, opts do
    validated =
      opts
      |> Keyword.drop([:__orchid_workflow_ctx__, :__reporter_ctx__])
      |> NimbleOptions.validate!(@options_schema)

    git_url = validated[:git_url]
    git_branch = validated[:git_branch]
    output_dir = validated[:output_dir] |> Path.absname()
    deploy_dir = validated[:deploy_dir] |> Path.absname()
    push_to_remote? = validated[:push]

    commit_message =
      validated[:commit_message] || "Site updated on #{DateTime.utc_now() |> DateTime.to_iso8601()}"

    if push_to_remote? do
      repo = setup_repo(git_url, git_branch, deploy_dir)
      copy_build_files(output_dir, deploy_dir)
      Logger.info("Committing and pushing to remote: #{git_url} [#{git_branch}]")
      commit_and_push(repo, commit_message)
    else
      Logger.info("Skipping git push. Dry-run mode for deployment to #{git_url}")
    end

    ok(:ok)
  end

  defp setup_repo(git_url, git_branch, deploy_dir) do
    if valid_repo?(deploy_dir) do
      Logger.info("Found existing deploy repository at #{deploy_dir}")
      %Git.Repository{path: deploy_dir}
    else
      Logger.info("Cloning deploy repository to #{deploy_dir}")
      File.rm_rf!(deploy_dir)

      repo = Git.clone!([git_url, deploy_dir])

      case Git.checkout(repo, [git_branch]) do
        {:ok, _} ->
          Logger.info("Checked out branch #{git_branch}")

        {:error, _} ->
          Logger.info("Creating new branch #{git_branch}")
          Git.checkout(repo, ["-b", git_branch])
      end

      repo
    end
  end

  defp valid_repo?(path) do
    File.exists?(path) and File.exists?(Path.join(path, ".git"))
  end

  defp copy_build_files(source_dir, target_dir) do
    Logger.info("Copying built files from #{source_dir} to #{target_dir}")

    if File.exists?(target_dir) do
      File.ls!(target_dir)
      |> Enum.reject(&(&1 == ".git"))
      |> Enum.each(fn item ->
        File.rm_rf!(Path.join(target_dir, item))
      end)
    end

    files = list_all_files(source_dir)

    Enum.each(files, fn file ->
      relative_path = Path.relative_to(file, source_dir)
      target_file = Path.join(target_dir, relative_path)

      File.mkdir_p!(Path.dirname(target_file))
      File.copy!(file, target_file)
    end)
  end

  defp list_all_files(dir) do
    if File.dir?(dir) do
      File.ls!(dir)
      |> Enum.map(&Path.join(dir, &1))
      |> Enum.flat_map(fn path ->
        if File.dir?(path) do
          list_all_files(path)
        else
          [path]
        end
      end)
    else
      []
    end
  end

  defp commit_and_push(repo, message) do
    Git.add(repo, ["."])

    case Git.commit(repo, ["-m", message]) do
      {:ok, _} ->
        Logger.info("Changes committed successfully")

        case Git.push(repo) do
          {:ok, output} -> Logger.info("Push successful: #{output}")
          {:error, err} -> Logger.error("Push failed: #{inspect(err)}")
        end

      {:error, err} ->
        Logger.info("Nothing to commit or commit failed: #{inspect(err)}")
    end
  end
end
