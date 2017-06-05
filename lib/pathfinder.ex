defmodule Graph.Pathfinder do
  @moduledoc false

  def get_shortest_path(%Graph{edges: edges, vertices: vertices, ids: ids} = g, a, b) do
    case Map.get(vertices, a) do
      nil ->
        nil
      a_id ->
        case Map.get(vertices, b) do
          nil ->
            nil
          b_id ->
            case Map.get(edges, a_id) do
              nil ->
                nil
              a_out ->
                tree = Graph.new |> Graph.add_vertex(a_id)
                q = :queue.new()
                q = a_out |> MapSet.to_list |> List.foldl(q, fn id, q -> :queue.in({a_id, id}, q) end)
                case do_shortpath(q, g, b_id, tree) do
                  nil ->
                    nil
                  path ->
                    for id <- path, do: Map.get(ids, id)
                end
            end
        end
    end
  end

  def get_paths(%Graph{edges: edges, vertices: vertices, ids: ids} = g, a, b) do
    case Map.get(vertices, a) do
      nil ->
        nil
      a_id ->
        case Map.get(vertices, b) do
          nil ->
            nil
          b_id ->
            a_neighbors = Map.get(edges, a_id)
            case build_paths(g, a_neighbors, b_id, [a_id], []) do
              nil -> nil
              paths ->
                for path <- paths do
                  for id <- path, do: Map.get(ids, id)
                end
            end
        end
    end
  end

  ## Private

  defp do_shortpath(q, %Graph{edges: edges} = g, target_id, tree) do
    case :queue.out(q) do
      {{:value, {v_id, ^target_id}}, _q1} ->
        follow_path(v_id, tree, [target_id])
      {{:value, {v1_id, v2_id}}, q1} ->
        if Map.has_key?(tree.vertices, v2_id) do
          do_shortpath(q1, g, target_id, tree)
        else
          case Map.get(edges, v2_id) do
            nil ->
              do_shortpath(q1, g, target_id, tree)
            v2_out ->
              tree = tree |> Graph.add_vertex(v2_id) |> Graph.add_edge(v2_id, v1_id)
              q2 = v2_out |> MapSet.to_list |> List.foldl(q1, fn id, q -> :queue.in({v2_id, id}, q) end)
              do_shortpath(q2, g, target_id, tree)
          end
        end
      {:empty, _} ->
        nil
    end
  end

  defp follow_path(v_id, %Graph{vertices: vertices, ids: ids, edges: edges} = tree, path) do
    path = [v_id | path]
    v_id_tree = Map.get(vertices, v_id)
    case edges |> Map.get(v_id_tree, MapSet.new) |> MapSet.to_list do
      [] ->
        path
      [next_id] ->
        follow_path(Map.get(ids, next_id), tree, path)
    end
  end

  defp build_paths(%Graph{} = g, neighbors, target_id, path, acc) do
    if MapSet.member?(neighbors, target_id) do
      [Enum.reverse([target_id|path]) | acc]
    else
      neighbors = MapSet.difference(neighbors, MapSet.new(path))
      check_neighbors(g, MapSet.to_list(neighbors), target_id, path, acc)
    end
  end

  defp check_neighbors(_g, [], _target_id, _path, acc) do
    acc
  end
  defp check_neighbors(%Graph{edges: es} = g, [next_neighbor_id|neighbors], target_id, path, acc) do
    next_neighbors = Map.get(es, next_neighbor_id)
    case build_paths(g, next_neighbors, target_id, [next_neighbor_id | path], acc) do
      nil ->
        check_neighbors(g, neighbors, target_id, path, acc)
      paths ->
        check_neighbors(g, neighbors, target_id, path, paths)
    end
  end
end