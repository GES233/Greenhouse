defmodule Greenhouse.Params.Media do
  @moduledoc """
  媒体资源本体优先。

  先得有这么个本体，才能够被注册，正文有对应的样式才可能被替换。

  ### Examples

      Greenhouse.Params.Media.all_in_one(
        "D:/Blog/source/img/snippet/zhihu-answer-3062464204.png",
        "D:/CodeRepo/ElixirPlayground/greenhouse",
        Greenhouse.Params.Media.Picture
      )
  """
  @type t :: %__MODULE__{
          id: binary() | atom(),
          abs_loc: Path.t(),
          route_path: binary(),
          type: module()
        }
  defstruct [
    :id,
    :abs_loc,
    :route_path,
    :type
  ]

  @type real_path :: Path.t()

  @type route_path :: binary()

  @callback route_handler(location_info :: any()) :: {binary(), route_path()}

  @callback convert_handler(
              source_path :: real_path(),
              target_root_path :: real_path(),
              route_path()
            ) ::
              {:ok, real_path()} | {:error, term()}

  # No Operate
  def all_in_one(path, handler) when is_binary(path) do
    {id, router} = handler.route_handler(path)

    %__MODULE__{id: id, route_path: router, type: handler, abs_loc: path}
  end

  # With Operate
  def all_in_one(path, target_root, handler) when is_binary(path) do
    {id, router} = handler.route_handler(path)

    dest_path =
      handler.convert_handler(path, target_root, router)
      |> case do
        {:ok, dest_path} -> dest_path
        _err -> nil
      end

    %__MODULE__{id: id, route_path: router, type: handler, abs_loc: dest_path}
  end

  # Allow max 2 nested
  def maybe_series(path, root) do
    [series, maybe_root] = path |> Path.split() |> Enum.reverse() |> Enum.slice(1..2)

    [id_under_seires, ext] = Path.basename(path) |> String.split(".")

    case maybe_root do
      ^root -> {[series, id_under_seires] |> Enum.join("-"), {series, id_under_seires, ext}}
      _ -> {id_under_seires, {id_under_seires, ext}}
    end
  end
end

defmodule Greenhouse.Params.Media.Picture do
  @behaviour Greenhouse.Params.Media

  @impl true
  def route_handler(path) do
    {id, router} = get_id_and_route(path)

    {id, "![](#{router})"}
  end

  @impl true
  def convert_handler(source_path, target_root_path, router) do
    dest_path = Path.join(target_root_path, router)

    # Solve when recursive
    File.mkdir_p(Path.dirname(dest_path))

    File.copy(source_path, dest_path)
    |> case do
      {:ok, _} -> {:ok, dest_path}
      err -> err
    end
  end

  defp get_id_and_route(path) do
    case Greenhouse.Params.Media.maybe_series(path, "img") do
      {id, {series, id_under_seires, ext}} -> {id, "/image/#{series}/#{id_under_seires}.#{ext}"}
      {id, {id_under_seires, ext}} -> {id, "/image/#{id_under_seires}.#{ext}"}
    end
  end
end

defmodule Greenhouse.Params.Media.Graphviz do
  # @behaviour Greenhouse.Params.Media

  defmodule Runner do
    def get_dot(), do: System.find_executable("dot") || "dot"

    # AIO
    # dot -Tsvg "d:/Blog/source/src/Hypothalamus-pipuitory-axis.dot" > "saved.svg"
    def execute(dot_path) do
      System.shell("#{get_dot()} -Tsvg \"#{dot_path}\"")
      |> handle_result()
    end

    defp handle_result({res, 0}), do: {:ok, res}
    defp handle_result({err, code}), do: {:error, {code, err}}
  end

  def route_handler(location) do
    {id, router_path} = get_id_and_route(location)

    {id, "![](#{router_path})"}
  end

  defp get_id_and_route(location) do
    case Greenhouse.Params.Media.maybe_series(location, "src") do
      {id, {series, id_under_seires, ext}} -> {id, "/svg/#{series}/#{id_under_seires}.#{ext}"}
      {id, {id_under_seires, ext}} -> {id, "/svg/#{id_under_seires}.#{ext}"}
    end
  end
end
