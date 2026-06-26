# Greenhouse

A project used to measure feasibility for [orchid](https://hex.pm/packages/orchid) in order to replace old [blog engine](https://github.com/GES233/simple_blog_engine).

## FlowChart

```mermaid
flowchart LR
    index_posts_map(["posts_map"]) -.-> index
    index_tags_map(["tags_map"]) -.-> index
    index_series_map(["series_map"]) -.-> index
    index_cat_map(["cat_map"]) -.-> index
    markdown_posts_content_map(["content_map"]) -.-> markdown_posts
    markdown_posts_bib_entry(["bib_entry"]) -.-> markdown_posts
    markdown_pages_content_map(["content_map"]) -.-> markdown_pages
    markdown_pages_bib_entry(["bib_entry"]) -.-> markdown_pages
    layout_posts_map_with_doc_struct(["map_with_doc_struct"]) -.-> layout_posts
    layout_pages_map_with_doc_struct(["map_with_doc_struct"]) -.-> layout_pages
    load_images_pic_path(["pic_path"]) -.-> load_images
    load_dots_dot_path(["dot_path"]) -.-> load_dots
    load_pdfs_pdf_path(["pdf_path"]) -.-> load_pdfs
    load_posts_posts_path(["posts_path"]) -.-> load_posts
    load_pages_page_root_path(["page_root_path"]) -.-> load_pages
    assets -->|"asset_status"| deploy
    taxonomy -->|"categories_posts_mapper"| index
    merge_media -->|"media_map"| media_export
    merge_media -->|"media_map"| replace_link
    load_pages -->|"pages_map"| replace_link
    markdown_pages -->|"pages_map_with_doc_struct"| layout_pages
    load_pdfs -->|"pdf_map"| merge_media
    load_images -->|"pic_map"| merge_media
    layout_posts -->|"post_ids"| assets
    load_posts -->|"posts_map"| replace_link
    load_posts -->|"posts_map"| taxonomy
    markdown_posts -->|"posts_map_with_doc_struct"| index
    markdown_posts -->|"posts_map_with_doc_struct"| layout_posts
    replace_link -->|"replaced_pages_map"| markdown_pages
    replace_link -->|"replaced_posts_map"| markdown_posts
    taxonomy -->|"series_posts_mapper"| index
    load_dots -->|"svg_map"| merge_media
    taxonomy -->|"tags_posts_mapper"| index
    index["Pipeline.IndexSteps"]
    markdown_posts["Steps.MarkdownToHTML"]
    markdown_pages["Steps.MarkdownToHTML"]
    layout_posts["Pipeline.LayoutSteps"]
    layout_pages["Pipeline.LayoutSteps"]
    merge_media["Media.MergeMedia"]
    load_images["Media.LoadImages"]
    load_dots["Media.LoadDots"]
    load_pdfs["Media.LoadPdfs"]
    replace_link["Pipeline.ContentSteps.ReplaceLink"]
    load_posts["Pipeline.ContentSteps.LoadPosts"]
    load_pages["Pipeline.ContentSteps.LoadPages"]
    taxonomy["Pipeline.TaxonomyStep"]
    media_export["Pipeline.MediaExportStep"]
    assets["Pipeline.AssetSteps"]
    deploy["Pipeline.DeployStep"]
```
