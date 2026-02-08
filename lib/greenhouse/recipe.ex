defmodule Greenhouse.Recipe do
  alias Greenhouse.Steps, as: S
  alias Orchid.Recipe, as: R

  def init_building() do
    recipe = build()

    {:error, {:missing_inputs, init_keys_required}} = R.validate_steps(recipe.steps, [])

    {
      # Orchid 0.5.2 not support pop name option
      # will add in 0.5.3
      %{recipe | name: :init},
      init_keys_required |> Enum.map(fn {_, v} -> v end) |> List.flatten()
    }
  end

  def build() do
    R.new(
      List.flatten([
        {Greenhouse.Content.PostsLoader, :posts_path, :posts_map, []},
        {Greenhouse.Content.PageLoader, :page_root_path, :pages_map, []},
        S.MediaLoader.as_declarative(),
        S.ContentReplacer.as_declarative(),
        S.HTMLConvertorWithBibliography.as_declarative()
      ]),
      name: :build
    )
  end
end
