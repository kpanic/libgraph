defmodule Graph.Serializers.Mermaid do
  @moduledoc """
  This serializer converts a Graph to a markdown Mermaid file, ready to be
  rendered via the `mmdc` mermadjs command.
  """
  use Graph.Serializer
  alias Graph.Serializer

  def serialize(%Graph{} = g) do
    result = "graph TB\n" <> serialize_nodes(g) <> serialize_edges(g) <> "\n"
    {:ok, result}
  end

  defp serialize_nodes(%Graph{vertices: vertices} = g) do
    Enum.reduce(vertices, "", fn {id, v}, acc ->
      acc <>
        Serializer.indent(1) <> "#{id}((" <> Serializer.get_vertex_label(g, id, v) <> "))\n"
    end)
  end

  defp serialize_edges(%Graph{vertices: vertices, out_edges: oe, edges: em} = _g) do
    edges =
      Enum.reduce(vertices, [], fn {id, _v}, acc ->
        edges =
          oe
          |> Map.get(id, MapSet.new())
          |> Enum.flat_map(fn id2 ->
            Enum.map(Map.fetch!(em, {id, id2}), fn
              {nil, weight} ->
                {id, id2, weight}

              {label, weight} ->
                {id, id2, weight, Serializer.encode_label(label)}
            end)
          end)

        case edges do
          [] -> acc
          _ -> acc ++ edges
        end
      end)

    Enum.reduce(edges, "", fn
      {v_id, v2_id, weight, edge_label}, acc ->
        acc <>
          Serializer.indent(1) <>
          "#{v_id} --> #{v2_id}((" <> "label=#{edge_label}, weight=#{weight}" <> "))\n"

      {v_id, v2_id, weight}, acc ->
        acc <>
          Serializer.indent(1) <>
          "#{v_id} --> #{v2_id}((" <> "weight=#{weight}" <> "))\n"
    end)
  end
end
