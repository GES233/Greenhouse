defmodule Greenhouse.Pipeline.Graph.Mermaid do
  @moduledoc """
  Generates Mermaid flowchart diagrams from `Oi.Topology.Graph`.
  """

  alias Oi.Topology.Graph
  alias Oi.Topology.Graph.{Node, Edge}

  @doc """
  Generates a Mermaid `flowchart LR` diagram from a built graph.

  Reads node labels from `node.container` and derives external
  inputs from ports with no incoming edges.
  """
  @spec to_mermaid(Graph.t()) :: String.t()
  def to_mermaid(%Graph{nodes: nodes, edges: edges}) do
    upstream = upstream_ports(edges)

    node_lines =
      for {id, %Node{container: container}} <- nodes do
        format_node(id, short_name(container))
      end

    input_lines =
      for {id, %Node{inputs: inputs}} <- nodes,
          port <- inputs,
          not MapSet.member?(upstream, {id, port}) do
        format_input(id, port)
      end

    edge_lines =
      for %Edge{from_node: fn_, from_port: fp, to_node: tn} <- edges do
        format_edge(fn_, fp, tn)
      end

    (["flowchart LR"] ++ input_lines ++ edge_lines ++ node_lines)
    |> Enum.join("\n")
  end

  defp format_node(id, label) do
    "    " <> Atom.to_string(id) <> "[\"" <> label <> "\"]"
  end

  defp format_input(id, port) do
    id_s = Atom.to_string(id)
    port_s = Atom.to_string(port)
    "    " <> id_s <> "_" <> port_s <> "([\"" <> port_s <> "\"]) -.-> " <> id_s
  end

  defp format_edge(fn_, fp, tn) do
    "    " <> Atom.to_string(fn_) <> " -->|\"" <> Atom.to_string(fp) <> "\"| " <> Atom.to_string(tn)
  end

  defp upstream_ports(edges) do
    for %Edge{to_node: n, to_port: p} <- edges, into: MapSet.new(), do: {n, p}
  end

  defp short_name(module) do
    module |> inspect() |> String.replace_prefix("Greenhouse.", "")
  end
end
