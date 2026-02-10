defmodule Orchid.Visualizer do
  defstruct [:name, :nodes, :edges]

  @spec build(Orchid.Recipe.t()) :: %__MODULE__{edges: any(), name: any(), nodes: any()}
  def build(%Orchid.Recipe{} = recipe) do
    do_build(recipe.name, recipe.steps, recipe.opts)
  end

  def do_build(name, steps, _recipe_opts) do
    steps = steps |> Enum.map(&Orchid.Step.extract_schema/1)

    # 1. 预处理：建立 "生产者映射表" (Key -> {NodeID, HandleName})
    #    这让我们知道某个变量是由 "谁" 的 "哪个端口" 生产的
    producer_map = build_producer_map(steps)

    # 2. 构建节点和边
    {nodes, edges} =
      steps
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {step_def, index}, {nodes_acc, edges_acc} ->
        step_id = "step_#{index}"

        # 解析该步骤定义的输入和输出端口
        {_func, input_shape, output_shape} = step_def
        input_ports = normalize_ports(input_shape)   # e.g. ["mid_a", "mid_b"]
        output_ports = normalize_ports(output_shape) # e.g. ["out1", "mid_d"]

        # --- A. 构建节点 ---
        node = %{
          id: step_id,
          label: get_label(step_def, index),
          type: get_type(step_def),
          # 这里是新增的关键字段，前端根据这个渲染圆点
          data: %{
            inputs: input_ports,
            outputs: output_ports
          }
        }

        # --- B. 构建边 ---
        # 遍历这个节点需要的所有输入端口，寻找它们的来源
        new_edges =
          Enum.map(input_ports, fn port_name ->
            # 查找是谁生产了这个 port_name (即变量名)
            case Map.get(producer_map, port_name) do
              nil ->
                # 可能是初始参数 (Initial Params)，或者不存在的依赖
                # 可以选择忽略，或者创建一个指向 "Global Context" 的边
                nil

              {source_node_id, source_handle} ->
                %{
                  id: "edge_#{source_node_id}_#{step_id}_#{port_name}",
                  source: source_node_id,
                  target: step_id,
                  sourceHandle: source_handle, # 连线的起点端口
                  targetHandle: port_name,     # 连线的终点端口
                  label: to_string(port_name)  # 连线上显示的变量名
                }
            end
          end)
          |> Enum.reject(&is_nil/1)

        {[node | nodes_acc], new_edges ++ edges_acc}
      end)

    # 3. 反转列表以保持顺序 (Reduce是从头到尾，List prepend是倒序)
    %__MODULE__{
      nodes: Enum.reverse(nodes),
      edges: Enum.reverse(edges),
      name: name
    }
  end

  # --- 辅助函数 ---

  # 建立变量名到生产者的映射
  defp build_producer_map(steps) do
    steps
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {{_func, _in, out_shape}, index}, acc ->
      step_id = "step_#{index}"
      ports = normalize_ports(out_shape)

      # 将该步骤产生的所有 output key 注册到 map 中
      Enum.reduce(ports, acc, fn port_name, map ->
        # Key: 变量名, Value: {生产该变量的节点ID, 对应的端口名}
        Map.put(map, port_name, {step_id, port_name})
      end)
    end)
  end

  # 将各种形状的 I/O 定义 (Atom, Tuple, List) 统一为字符串列表
  # { :a, :b } -> [:a, :b]
  # :a -> [:a]
  defp normalize_ports(shape) do
    case shape do
      nil -> []
      atom when is_atom(atom) -> [atom]
      list when is_list(list) -> list
      tuple when is_tuple(tuple) -> Tuple.to_list(tuple)
      _ -> []
    end
  end

  defp get_label({step_mod, _, _}, idx) when is_atom(step_mod) do
    step_mod
    |> Atom.to_string()
    # |> String.split(".")
    # |> List.last()
    |> then(&"[#{idx}]Step <#{&1}>")
  end

  defp get_label({step_impl, _, _}, idx) when is_function(step_impl, 2), do: "[#{idx}]Anonymous Fn #{inspect(step_impl)}"
  defp get_label({_, _, _}, idx), do: "[#{idx}]Step"

  defp get_type({mod, _, _}) when is_atom(mod), do: :module
  defp get_type({func, _, _}) when is_function(func), do: :function
end
