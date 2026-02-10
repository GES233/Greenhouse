# Greenhouse

A project used to measure feasibility for [orchid](https://hex.pm/packages/orchid) in order to replace old [blog engine](https://github.com/GES233/simple_blog_engine).

## FlowChart

```mermaid
flowchart TD
  %% Nodes
  step_0("[0]Anonymous Fn &Greenhouse.Pipeline.ContentSteps.load_posts/2")
  step_1("[1]Anonymous Fn &Greenhouse.Pipeline.ContentSteps.load_pages/2")
  step_2[["[2]Step Elixir.Orchid.Step.NestedStep"]]
  step_3("[3]Anonymous Fn &Greenhouse.Pipeline.ContentSteps.replace_link/2")
  step_4[["[4]Step Elixir.Greenhouse.Steps.MarkdownToHTML"]]
  step_5[["[5]Step Elixir.Greenhouse.Steps.MarkdownToHTML"]]
  step_6[["[6]Step Elixir.Greenhouse.Pipeline.TaxonomyStep"]]

  %% Edges
  step_2 -- "media_map" --> step_3
  step_1 -- "pages_map" --> step_3
  step_0 -- "posts_map" --> step_3
  step_3 -- "replaced_posts_map" --> step_4
  step_3 -- "replaced_pages_map" --> step_5
  step_0 -- "posts_map" --> step_6
```
