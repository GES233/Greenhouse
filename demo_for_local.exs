# Load
root_path = "source"
page_root_path = root_path
posts_path = Path.join(root_path, "_posts")
pic_path = Path.join(root_path, "img")
pdf_path = Path.join(root_path, "pdf")
dot_path = Path.join(root_path, "src")
bib_entry = Path.join(root_path, "_bibs")

# Enable pushing to remote GitHub Pages
Application.put_env(:greenhouse, :push_deploy, true)

inputs = %{
  "load_posts|posts_path" => posts_path,
  "load_pages|page_root_path" => page_root_path,
  "load_images|pic_path" => pic_path,
  "load_pdfs|pdf_path" => pdf_path,
  "load_dots|dot_path" => dot_path,
  "markdown_posts|bib_entry" => bib_entry,
  "markdown_pages|bib_entry" => bib_entry
}

graph = Greenhouse.Pipeline.Graph.build()
{:ok, compiled} = Oi.compile(graph)

_res = Oi.execute(compiled, inputs: inputs) |> case do
  {:ok, res} -> res
  {:error, err} -> err
end
