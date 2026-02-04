# Load
root_path = "D:/Blog/source"
page_root_path = root_path
posts_path = Path.join(root_path, "_posts")
pic_path = Path.join(root_path, "img")
pdf_path = Path.join(root_path, "pdf")
dot_path = Path.join(root_path, "src")

import Orchid.ParamFactory

# Run
Orchid.run(Greenhouse.Recipe.build(), [
  to_param(page_root_path, :path),
  to_param(posts_path, :path),
  to_param(pic_path, :path),
  to_param(pdf_path, :path),
  to_param(dot_path, :path)
])
