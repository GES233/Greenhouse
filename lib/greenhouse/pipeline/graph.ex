defmodule Greenhouse.Pipeline.Graph do
  @moduledoc """
  Builds the Oi.Topology.Graph for the Greenhouse build pipeline.
  """

  import Oi.Flowgraph
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

  @doc """
  External input nodes and their ports expected by `Oi.execute/2`'s `:data` option.
  """
  @spec external_inputs() :: %{atom() => [atom()]}
  def external_inputs do
    %{
      load_posts: [:posts_path],
      load_pages: [:page_root_path],
      load_images: [:pic_path],
      load_pdfs: [:pdf_path],
      load_dots: [:dot_path],
      markdown_posts: [:bib_entry],
      markdown_pages: [:bib_entry]
    }
  end

  @step_modules [
    LoadPosts,
    LoadPages,
    LoadImages,
    LoadPdfs,
    LoadDots,
    MergeMedia,
    ReplaceLink,
    MarkdownToHTML,
    TaxonomyStep,
    LayoutSteps,
    MediaExportStep,
    IndexSteps,
    AssetSteps,
    DeployStep
  ]

  @spec build() :: Oi.Topology.Graph.t()
  def build do
    _ = Enum.each(@step_modules, &Code.ensure_loaded!/1)

    new_flowchart()
    |> add_step(LoadPosts)
    |> add_step(LoadPages)
    |> add_step(LoadImages)
    |> add_step(LoadPdfs)
    |> add_step(LoadDots)
    |> add_step(MergeMedia)
    |> add_step(ReplaceLink)
    |> add_step(MarkdownToHTML, as: :markdown_posts)
    |> add_step(MarkdownToHTML, as: :markdown_pages)
    |> add_step(TaxonomyStep)
    |> add_step(LayoutSteps, as: :layout_posts, opts: [theme: Greenhouse.Theme.MobileFriendly])
    |> add_step(LayoutSteps, as: :layout_pages, opts: [theme: Greenhouse.Theme.MobileFriendly])
    |> add_step(MediaExportStep)
    |> add_step(IndexSteps, opts: [theme: Greenhouse.Theme.MobileFriendly])
    |> add_step(AssetSteps)
    |> add_step(DeployStep, opts: deploy_opts())
    |> connect({:load_images, :pic_map}, {:merge_media, :pic_map})
    |> connect({:load_dots, :svg_map}, {:merge_media, :svg_map})
    |> connect({:load_pdfs, :pdf_map}, {:merge_media, :pdf_map})
    |> connect({:load_posts, :posts_map}, {:replace_link, :posts_map})
    |> connect({:load_pages, :pages_map}, {:replace_link, :pages_map})
    |> connect({:merge_media, :media_map}, {:replace_link, :media_map})
    |> connect({:replace_link, :replaced_posts_map}, {:markdown_posts, :replaced_posts_map})
    |> connect({:replace_link, :replaced_pages_map}, {:markdown_pages, :replaced_pages_map})
    |> connect({:load_posts, :posts_map}, {:taxonomy, :posts_map})
    |> connect({:markdown_posts, :posts_map_with_doc_struct}, {:layout_posts, :posts_map_with_doc_struct})
    |> connect({:markdown_pages, :pages_map_with_doc_struct}, {:layout_pages, :pages_map_with_doc_struct})
    |> connect({:merge_media, :media_map}, {:media_export, :media_map})
    |> connect({:markdown_posts, :posts_map_with_doc_struct}, {:index, :posts_map_with_doc_struct})
    |> connect({:taxonomy, :tags_posts_mapper}, {:index, :tags_posts_mapper})
    |> connect({:taxonomy, :series_posts_mapper}, {:index, :series_posts_mapper})
    |> connect({:taxonomy, :categories_posts_mapper}, {:index, :categories_posts_mapper})
    |> connect({:layout_posts, :post_ids}, {:assets, :post_ids})
    |> connect({:assets, :asset_status}, {:deploy, :asset_status})
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
end
