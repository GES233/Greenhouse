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
  # External input nodes and their ports expected by `Oi.execute/2`'s `:data` option.

  @spec build() :: Oi.Topology.Graph.t()
  def build do
    graph do
      many_step([LoadPosts, LoadPages, LoadImages, LoadPdfs, LoadDots, MergeMedia, ReplaceLink])
      step(MarkdownToHTML, as: :markdown_posts)
      step(MarkdownToHTML, as: :markdown_pages)
      step(TaxonomyStep)
      step(LayoutSteps, as: :layout_posts, opts: [theme: Greenhouse.Theme.MobileFriendly])
      step(LayoutSteps, as: :layout_pages, opts: [theme: Greenhouse.Theme.MobileFriendly])
      step(MediaExportStep)
      step(IndexSteps, opts: [theme: Greenhouse.Theme.MobileFriendly])
      step(AssetSteps)
      step(DeployStep, opts: deploy_opts())

      # Media -> Merge
      load_images.pic_map ~> merge_media.pic_map
      load_dots.svg_map ~> merge_media.svg_map
      load_pdfs.pdf_map ~> merge_media.pdf_map

      # Content -> ReplaceLink
      load_posts.posts_map ~> replace_link.posts_map
      load_pages.pages_map ~> replace_link.pages_map
      merge_media.media_map ~> replace_link.media_map

      # ReplaceLink -> Markdown (content_map = step input port)
      replace_link.replaced_posts_map ~> markdown_posts.content_map
      replace_link.replaced_pages_map ~> markdown_pages.content_map

      # Posts -> Taxonomy (raw, pre-markdown)
      load_posts.posts_map ~> taxonomy.posts_map

      # Markdown -> Layout (with_doc_struct = step output, map_with_doc_struct = layout input)
      markdown_posts.with_doc_struct ~> layout_posts.map_with_doc_struct
      markdown_pages.with_doc_struct ~> layout_pages.map_with_doc_struct

      # Media -> MediaExport
      merge_media.media_map ~> media_export.media_map

      # Markdown + Taxonomy -> Index
      markdown_posts.with_doc_struct ~> index.posts_map
      taxonomy.tags_posts_mapper ~> index.tags_map
      taxonomy.series_posts_mapper ~> index.series_map
      taxonomy.categories_posts_mapper ~> index.cat_map

      # Layout -> Assets -> Deploy
      layout_posts.ids ~> assets.post_ids
      assets.asset_status ~> deploy.asset_status
    end
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
