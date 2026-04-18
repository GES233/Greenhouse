defmodule Greenhouse.Layout.Components do
  alias Greenhouse.Content.Post

  ## Title

  ## Meta

  def get_options(%Post{extra: raw_option}) do
    {_, option} = Map.pop(raw_option, "pandoc")

    option
  end
end
