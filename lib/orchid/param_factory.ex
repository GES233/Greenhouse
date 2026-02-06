defmodule Orchid.ParamFactory do
  # 必须 require 才能使用宏

  @doc """
  读取变量名作为 name，变量值作为 payload。
  用法: to_param(root_path, :path)
  """
  defmacro to_param(var_ast, type, metadata \\ Macro.escape(%{})) do
    # 1. 从 AST 中提取变量名
    # Elixir 中变量的 AST 通常长这样: {:root_path, [line: 1], nil}
    var_name =
      case var_ast do
        {name, _meta, _ctx} when is_atom(name) -> name
        _ -> raise ArgumentError, "to_param/3 expects a variable, got: #{inspect(var_ast)}"
      end

    # 2. 生成调用 Orchid.Param.new 的代码
    quote do
      Orchid.Param.new(
        # 这里注入提取出来的原子，例如 :root_path
        unquote(var_name),
        # 这里注入类型
        unquote(type),
        # 这里注入变量本身的值
        unquote(var_ast),
        unquote(metadata)
      )
    end
  end
end
