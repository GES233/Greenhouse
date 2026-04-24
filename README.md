# Greenhouse

A project used to measure feasibility for [orchid](https://hex.pm/packages/orchid) in order to replace old [blog engine](https://github.com/GES233/simple_blog_engine).

## FlowChart

```mermaid
graph TD
    step_0["⚙️ Anonymous Function"]:::stepClass
    posts_path(["posts_path"]) -.-> step_0
    step_0 ==> posts_map(["posts_map"])
    step_1["⚙️ Anonymous Function"]:::stepClass
    page_root_path(["page_root_path"]) -.-> step_1
    step_1 ==> pages_map(["pages_map"])
    step_2["⚙️ Orchid.Step.NestedStep"]:::stepClass
    pic_path(["pic_path"]) -.-> step_2
    pdf_path(["pdf_path"]) -.-> step_2
    dot_path(["dot_path"]) -.-> step_2
    step_2 ==> media_map(["media_map"])
    step_3["⚙️ Anonymous Function"]:::stepClass
    posts_map(["posts_map"]) -.-> step_3
    pages_map(["pages_map"]) -.-> step_3
    media_map(["media_map"]) -.-> step_3
    step_3 ==> replaced_posts_map(["replaced_posts_map"])
    step_3 ==> replaced_pages_map(["replaced_pages_map"])
    step_4["⚙️ Greenhouse.Steps.MarkdownToHTML"]:::stepClass
    replaced_posts_map(["replaced_posts_map"]) -.-> step_4
    bib_entry(["bib_entry"]) -.-> step_4
    step_4 ==> posts_map_with_doc_struct(["posts_map_with_doc_struct"])
    step_5["⚙️ Greenhouse.Steps.MarkdownToHTML"]:::stepClass
    replaced_pages_map(["replaced_pages_map"]) -.-> step_5
    bib_entry(["bib_entry"]) -.-> step_5
    step_5 ==> pages_map_with_doc_struct(["pages_map_with_doc_struct"])
    step_6["⚙️ Greenhouse.Pipeline.TaxonomyStep"]:::stepClass
    posts_map(["posts_map"]) -.-> step_6
    step_6 ==> tags_posts_mapper(["tags_posts_mapper"])
    step_6 ==> series_posts_mapper(["series_posts_mapper"])
    step_6 ==> categories_posts_mapper(["categories_posts_mapper"])
    step_7["⚙️ Greenhouse.Pipeline.LayoutSteps"]:::stepClass
    posts_map_with_doc_struct(["posts_map_with_doc_struct"]) -.-> step_7
    step_7 ==> post_ids(["post_ids"])
    step_8["⚙️ Greenhouse.Pipeline.LayoutSteps"]:::stepClass
    pages_map_with_doc_struct(["pages_map_with_doc_struct"]) -.-> step_8
    step_8 ==> page_ids(["page_ids"])
    step_9["⚙️ Greenhouse.Pipeline.MediaExportStep"]:::stepClass
    media_map(["media_map"]) -.-> step_9
    step_9 ==> media_export_status(["media_export_status"])
    step_10["⚙️ Greenhouse.Pipeline.IndexSteps"]:::stepClass
    posts_map_with_doc_struct(["posts_map_with_doc_struct"]) -.-> step_10
    tags_posts_mapper(["tags_posts_mapper"]) -.-> step_10
    series_posts_mapper(["series_posts_mapper"]) -.-> step_10
    categories_posts_mapper(["categories_posts_mapper"]) -.-> step_10
    step_10 ==> index_status(["index_status"])
    step_11["⚙️ Greenhouse.Pipeline.AssetSteps"]:::stepClass
    post_ids(["post_ids"]) -.-> step_11
    step_11 ==> asset_status(["asset_status"])
    step_12["⚙️ Greenhouse.Pipeline.DeployStep"]:::stepClass
    asset_status(["asset_status"]) -.-> step_12
    step_12 ==> deploy_status(["deploy_status"])

    classDef stepClass fill:#2eb82e,stroke:#fff,stroke-width:2px,color:#fff;
```
