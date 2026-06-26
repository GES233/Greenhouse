# Greenhouse

A project used to measure feasibility for [orchid](https://hex.pm/packages/orchid) in order to replace old [blog engine](https://github.com/GES233/simple_blog_engine).

## FlowChart

```mermaid
graph LR
    load_pages_page_root_path(["page_root_path"]) -.-> load_pages
    markdown_pages_bib_entry(["bib_entry"]) -.-> markdown_pages
    load_pdfs_pdf_path(["pdf_path"]) -.-> load_pdfs
    load_images_pic_path(["pic_path"]) -.-> load_images
    load_posts_posts_path(["posts_path"]) -.-> load_posts
    markdown_posts_bib_entry(["bib_entry"]) -.-> markdown_posts
    load_dots_dot_path(["dot_path"]) -.-> load_dots
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
    assets["AssetSteps"]
    deploy["DeployStep"]
    taxonomy["TaxonomyStep"]
    index["IndexSteps"]
    merge_media["Media.MergeMedia"]
    media_export["MediaExportStep"]
    replace_link["ContentSteps.ReplaceLink"]
    load_pages["ContentSteps.LoadPages"]
    markdown_pages["MarkdownToHTML"]
    layout_pages["LayoutSteps"]
    load_pdfs["Media.LoadPdfs"]
    load_images["Media.LoadImages"]
    layout_posts["LayoutSteps"]
    load_posts["ContentSteps.LoadPosts"]
    markdown_posts["MarkdownToHTML"]
    load_dots["Media.LoadDots"]
```
