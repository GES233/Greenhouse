defmodule Greenhouse.Layout.View do
  require EEx

  EEx.function_from_file(:def, :scaffold, "priv/layout/scaffold.html.eex", [:assigns])
end
