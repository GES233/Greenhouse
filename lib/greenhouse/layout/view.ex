defmodule Greenhouse.Layout.View do
  require EEx

  EEx.function_from_file(:def, :scaffold, "priv/layout/scaffold.html.eex", [:assigns])

  EEx.function_from_file(:def, :meta, "priv/layout/meta.html.eex", [:assigns])

  # EEx.function_from_file(:def, :prose, ...)

  # EEx.function_from_file(:def, :posts, ...)

  # EEx.function_from_file(:def, :pages, ...)

  # EEx.function_from_file(:def, :taxonomy, ...)
end
