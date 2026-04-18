# Greenhouse Agent Instructions

This document provides context and patterns for AI agents working in the Greenhouse codebase. Greenhouse is an Elixir-based blog engine/static site generator designed to replace `simple_blog_engine`. It utilizes a declarative data pipeline architecture powered by the `orchid` library.

## Project Architecture & Core Concepts

- **Data Pipeline Architecture**: The core build process is orchestrated as a Directed Acyclic Graph (DAG) using the `orchid` library. 
- **Recipes**: The workflow graph is defined as an `Orchid.Recipe`. The main build recipe is located in `lib/greenhouse/pipeline/recipe.ex`.
- **Steps**: Pipeline execution is divided into atomic steps. Steps can be module-based (implementing `Orchid.Step`) or function-based (2-arity functions).
  - You can find content loading steps in `lib/greenhouse/pipeline/content_steps.ex`.
  - A step receives and returns data wrapped as Orchid parameters.
- **Orchid Knowledge Base**: This repository contains a detailed internal skill for Orchid workflows. **If you need to create or modify pipeline steps, recipes, hooks, or nested workflows, always refer to `.agent/skills/elixir-orchid-workflow/SKILL.md` first.**

## Key Components

- **Pipeline (`lib/greenhouse/pipeline/`)**: Contains recipes and steps that dictate the static generation workflow (loading posts/pages, resolving media links, converting markdown to HTML, extracting taxonomies).
- **Content (`lib/greenhouse/content/`)**: Modules for parsing and loading raw source materials (pages, posts) from the filesystem, possibly referencing git histories for dates.
- **Layout/Assets (`lib/greenhouse/layout/`, `lib/greenhouse/asset/`)**: Handling views, components, and media. Uses `phoenix_html` and `tailwind`.
- **Cite (`lib/greenhouse/cite/`)**: Replaces markdown links to internal resources/media with correctly resolved HTML links.
- **Taxonomy (`lib/greenhouse/taxonomy/`)**: Builds relations for categories, tags, and series.
- **Theme/Render Engine (`lib/greenhouse/theme.ex`)**: A pluggable theming system. The rendering layer is entirely decoupled from the Orchid pipeline via the `Greenhouse.Theme` behaviour. Themes are configured dynamically via step options in `Greenhouse.Pipeline.LayoutSteps`.
- **Orchid Extensions (`lib/orchid/`)**: The project extends the base `orchid` library with local helpers in the `Orchid` namespace (e.g., `Orchid.ParamFactory`, `Orchid.Steps.Helpers`, `Orchid.Visualizer`).

## Essential Commands

- **Dependencies**: `mix deps.get`
- **Testing**: `mix test`
- **Formatting**: `mix format`
- **Running the Demo**: `elixir demo_for_local.exs` (Note: This script has hardcoded paths to `D:/Blog/source` and is used to test the pipeline locally).

## Conventions and Gotchas

- **Orchid Params**: Remember that Orchid step inputs and outputs aren't bare Elixir types; they are wrapped in `Orchid.Param`. When writing function steps, expect inputs like `%Orchid.Param{payload: data}` and return `{:ok, Orchid.Param.new(:name, :type, result)}` or use `Orchid.ParamFactory.to_param(result, :type)`.
- **NimbleOptions Validation**: Steps often validate their options using `NimbleOptions` (e.g., in `ContentSteps.load_posts/2`). Be sure to define schemas for any new step options.
- **Drop Native Orchid Opts**: Before validating step options with `NimbleOptions`, filter out Orchid's internal options by calling `Orchid.Steps.Helpers.drop_orchid_native(step_options)`.
- **Pluggable Themes**: When rendering HTML, the pipeline uses `Greenhouse.Pipeline.LayoutSteps`. Do not hardcode HTML rendering logic in pipeline steps. Instead, implement a module using the `Greenhouse.Theme` behaviour, and pass it to the step options (e.g., `theme: Greenhouse.Theme.Default`). The default theme uses `EEx` templates instead of LiveView/HEEx to keep the engine lightweight.
