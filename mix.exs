defmodule Greenhouse.MixProject do
  use Mix.Project

  def project do
    [
      app: :greenhouse,
      version: "0.1.0",
      elixir: "~> 1.18",
      # config_path: "config.exs",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Greenhouse.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Orchestration
      {:orchid, "~> 0.6"},
      {:orchid_symbiont, "~> 0.2"},
      {:oi, "~> 0.2", runtime: true},
      {:nimble_options, "~> 1.1"},

      # Meta parse
      {:yaml_elixir, "~> 2.12"},

      # Layout
      {:phoenix_html, "~> 4.3"},
      {:tailwind, "~> 0.4", runtime: Mix.env() == :dev},

      # Dev server
      {:plug_cowboy, "~> 2.7"},
      {:file_system, "~> 1.1"},

      # Git
      {:git_cli, "~> 0.3.0"}
    ]
  end
end
