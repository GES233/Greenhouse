defmodule Greenhouse.Pipeline.Graph do
  @moduledoc """
  Builds the Oi.Topology.Graph for the Greenhouse build pipeline.
  """

  alias Greenhouse.Pipeline.{
    TaxonomyStep,
    LayoutSteps,
    MediaExportStep,
    IndexSteps,
    AssetSteps,
    DeployStep
  }

  alias Greenhouse.Pipeline.ContentSteps.{LoadPosts, LoadPages, ReplaceLink}
  alias Greenhouse.Media.{LoadImages, LoadPdfs, LoadDots, MergeMedia}
  alias Greenhouse.Steps.MarkdownToHTML
  alias Oi.Topology.Graph
  alias Oi.Topology.Graph.{Node, Edge}

  @doc """
  External input keys expected by `Oi.execute/2`'s `:inputs` option.
  """
  @spec external_inputs() :: [String.t()]
  def external_inputs do
    [
      "load_posts|posts_path",
      "load_pages|page_root_path",
      "load_images|pic_path",
      "load_pdfs|pdf_path",
      "load_dots|dot_path",
      "markdown_posts|bib_entry",
      "markdown_pages|bib_entry"
    ]
  end

  @spec build() :: Graph.t()
  def build do
    Graph.new()
    |> Graph.add_node(node(:load_posts, LoadPosts, [:posts_path], [:posts_map]))
    |> Graph.add_node(node(:load_pages, LoadPages, [:page_root_path], [:pages_map]))
    |> Graph.add_node(node(:load_images, LoadImages, [:pic_path], [:pic_map]))
    |> Graph.add_node(node(:load_pdfs, LoadPdfs, [:pdf_path], [:pdf_map]))
    |> Graph.add_node(node(:load_dots, LoadDots, [:dot_path], [:svg_map]))
    |> Graph.add_node(node(:merge_media, MergeMedia, [:pic_map, :svg_map, :pdf_map], [:media_map]))
    |> Graph.add_node(node(:replace_link, ReplaceLink, [:posts_map, :pages_map, :media_map], [:replaced_posts_map, :replaced_pages_map]))
    |> Graph.add_node(node(:markdown_posts, MarkdownToHTML, [:replaced_posts_map, :bib_entry], [:posts_map_with_doc_struct]))
    |> Graph.add_node(node(:markdown_pages, MarkdownToHTML, [:replaced_pages_map, :bib_entry], [:pages_map_with_doc_struct]))
    |> Graph.add_node(node(:taxonomy, TaxonomyStep, [:posts_map], [:tags_posts_mapper, :series_posts_mapper, :categories_posts_mapper]))
    |> Graph.add_node(node(:layout_posts, LayoutSteps, [:posts_map_with_doc_struct], [:post_ids], theme: Greenhouse.Theme.MobileFriendly))
    |> Graph.add_node(node(:layout_pages, LayoutSteps, [:pages_map_with_doc_struct], [:page_ids], theme: Greenhouse.Theme.MobileFriendly))
    |> Graph.add_node(node(:media_export, MediaExportStep, [:media_map], [:media_export_status]))
    |> Graph.add_node(node(:index, IndexSteps, [:posts_map_with_doc_struct, :tags_posts_mapper, :series_posts_mapper, :categories_posts_mapper], [:index_status], theme: Greenhouse.Theme.MobileFriendly))
    |> Graph.add_node(node(:assets, AssetSteps, [:post_ids], [:asset_status]))
    |> Graph.add_node(node(:deploy, DeployStep, [:asset_status], [:deploy_status], deploy_opts()))
    |> add_edges()
  end

  # -- Node helpers --

  defp node(id, impl, inputs, outputs) do
    node(id, impl, inputs, outputs, [])
  end

  defp node(id, impl, inputs, outputs, opts) do
    %Node{
      id: id,
      container: impl,
      inputs: inputs,
      outputs: outputs,
      options: opts
    }
  end

  defp deploy_opts do
    [
      git_url:
        Application.get_env(:greenhouse, :git_deploy_url) ||
          "https://github.com/GES233/ges233.github.io.git",
      git_branch: "site",
      push: Application.get_env(:greenhouse, :push_deploy) || false
    ]
  end

  # -- Edges --

  defp add_edges(graph) do
    edges()
    |> Enum.reduce(graph, fn {from, from_port, to, to_port}, g ->
      Graph.add_edge(g, Edge.new(from, from_port, to, to_port))
    end)
  end

  defp edges do
    [
      # Media loading -> merge
      {:load_images, :pic_map, :merge_media, :pic_map},
      {:load_dots, :svg_map, :merge_media, :svg_map},
      {:load_pdfs, :pdf_map, :merge_media, :pdf_map},
      # Content loading -> replace_link
      {:load_posts, :posts_map, :replace_link, :posts_map},
      {:load_pages, :pages_map, :replace_link, :pages_map},
      {:merge_media, :media_map, :replace_link, :media_map},
      # replace_link -> markdown
      {:replace_link, :replaced_posts_map, :markdown_posts, :replaced_posts_map},
      {:replace_link, :replaced_pages_map, :markdown_pages, :replaced_pages_map},
      # posts_map also feeds taxonomy
      {:load_posts, :posts_map, :taxonomy, :posts_map},
      # markdown -> layout
      {:markdown_posts, :posts_map_with_doc_struct, :layout_posts, :posts_map_with_doc_struct},
      {:markdown_pages, :pages_map_with_doc_struct, :layout_pages, :pages_map_with_doc_struct},
      # media -> export
      {:merge_media, :media_map, :media_export, :media_map},
      # markdown + taxonomy -> index
      {:markdown_posts, :posts_map_with_doc_struct, :index, :posts_map_with_doc_struct},
      {:taxonomy, :tags_posts_mapper, :index, :tags_posts_mapper},
      {:taxonomy, :series_posts_mapper, :index, :series_posts_mapper},
      {:taxonomy, :categories_posts_mapper, :index, :categories_posts_mapper},
      # layout -> assets -> deploy
      {:layout_posts, :post_ids, :assets, :post_ids},
      {:assets, :asset_status, :deploy, :asset_status}
    ]
  end
end
