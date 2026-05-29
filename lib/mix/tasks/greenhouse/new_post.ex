defmodule Mix.Tasks.Greenhouse.NewPost do
  @moduledoc """
  Creates a new Markdown post in the posts source directory.

  ## Usage

      mix greenhouse.new_post "Post Title"
      mix greenhouse.new_post "Post Title" --slug my-slug --tags a,b --categories misc

  ## Options

    --slug        File slug (auto-generated from title if omitted)
    --tags        Comma-separated tags, e.g. `--tags elixir,otp`
    --categories  Comma-separated categories, e.g. `--categories dev,blog`
    --series      Series name
    --progress    Post status: `wip` or `final` (default: final)
    --date        Override date (default: now). Format: "YYYY-MM-DD HH:MM:SS"
    --path        Override posts output directory
  """

  use Mix.Task

  @shortdoc "Creates a new blog post"
  @default_path "D:/Blog/source/_posts"

  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args,
        strict: [
          slug: :string,
          tags: :string,
          categories: :string,
          series: :string,
          progress: :string,
          date: :string,
          path: :string
        ]
      )

    title =
      case positional do
        [t | _] -> t
        [] -> Mix.raise("Usage: mix greenhouse.new_post \"Post Title\"")
      end

    posts_path =
      opts[:path] || Application.get_env(:greenhouse, :posts_source_path) || @default_path

    slug = opts[:slug] || generate_slug(title)
    filename = "#{slug}.md"
    filepath = Path.join(posts_path, filename)

    if File.exists?(filepath) do
      Mix.raise("File already exists: #{filepath}")
    end

    progress = parse_progress(opts[:progress])
    frontmatter = build_frontmatter(title, opts, progress)
    content = frontmatter <> "\n\nStart writing here...\n"

    File.mkdir_p!(posts_path)
    File.write!(filepath, content)

    Mix.shell().info("Created: #{filepath}")
  end

  defp generate_slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\p{Han}]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "untitled-#{System.os_time(:second)}"
      slug -> slug
    end
  end

  defp parse_progress(nil), do: :final
  defp parse_progress("wip"), do: :wip
  defp parse_progress("final"), do: :final

  defp parse_progress(other) do
    Mix.raise("Invalid --progress value: #{other}. Expected: wip or final")
  end

  defp build_frontmatter(title, opts, progress) do
    now = NaiveDateTime.local_now() |> NaiveDateTime.truncate(:second)

    date_str =
      opts[:date] ||
        "#{now.year}-#{pad(now.month)}-#{pad(now.day)} #{pad(now.hour)}:#{pad(now.minute)}:#{pad(now.second)}"

    base = ["---", "title: #{escape_yaml(title)}", "date: #{date_str}"]

    base =
      if tags = opts[:tags] do
        tag_list = tags |> String.split(",") |> Enum.map(&String.trim/1) |> inspect()
        base ++ ["tags: #{tag_list}"]
      else
        base
      end

    base =
      if cats = opts[:categories] do
        cat_entries =
          cats
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&"  - [#{&1}]")

        base ++ ["categories:"] ++ cat_entries
      else
        base
      end

    base =
      if series = opts[:series] do
        base ++ ["series: #{escape_yaml(series)}"]
      else
        base
      end

    base =
      if progress != :final do
        base ++ ["progress: #{progress}"]
      else
        base
      end

    (base ++ ["---"]) |> Enum.join("\n")
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"

  defp escape_yaml(str) do
    # Always double-quote YAML values for safety.
    # Single-backslash for the inner quote, then YAML-safe output.
    escaped = String.replace(str, "\"", "\\\"")
    "\"#{escaped}\""
  end
end
