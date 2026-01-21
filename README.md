# Greenhouse

A project used to measure feasibility for [orchid](https://hex.pm/packages/orchid) in order to replace old [blog engine](https://github.com/GES233/simple_blog_engine).

## FlowChart

```mermaid
flowchart TD
  Inputs
  PL["PostsLoader"]
  ML["MediaLoader"]
  BE["BibliographyExtractor"]
  MR["MediaReplace"]
  iTB["TaxonomyBuilder"]
  APL["AddPostsLayout"]
  APgL["AddPagesLayout"]
  MO["MediaOperator"]

  Inputs --posts_path--> PL
  Inputs --media_path--> ML
  PL --posts_map--> MR
  ML --media_map--> MR
  MR --reallocated_posts_map--> BE
  %% Can be invoked anything
  %% If input is posts_map-like
  %% Because only some several fields were used
  BE --posts_map_with_bib--> iTB
  %% Options
  itb_opts("pagination, ...") --> iTB
  BE --posts_with_doc_struct--> APL
  APL --> o1("saved_path")
  iTB --indcies_metadata--> APgL
  APgL --> o2("saved_path")
  ML --media_map--> MO
  MO --> o3("saved_path")

```
