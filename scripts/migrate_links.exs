#!/usr/bin/env elixir
# Migration script: convert :{id} to [[id]] in all .md files
# Run: elixir scripts/migrate_links.exs

source_dir = Path.join(__DIR__, "../source")

Path.wildcard(Path.join(source_dir, "**/*.md"))
|> Enum.each(fn path ->
  original = File.read!(path)

  # Replace :{id} with [[id]], but NOT ::{ (Julia type annotation)
  updated =
    Regex.replace(~r/(?<!:):\{([^}]+)\}/, original, fn _full, id ->
      "[[#{id}]]"
    end)

  if updated != original do
    count =
      Regex.scan(~r/(?<!:):\{([^}]+)\}/, original) |> length()

    File.write!(path, updated)
    IO.puts("[#{count} replacements] #{Path.relative_to(path, source_dir)}")
  end
end)

IO.puts("\nDone.")
