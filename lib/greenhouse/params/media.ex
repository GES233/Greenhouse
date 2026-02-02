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
          type: module(),
          content_replaced: binary()
        }
  defstruct [
    :id,
    :abs_loc,
    :route_path,
    :type,
    :content_replaced
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
  def path_to_media(path, handler) when is_binary(path) do
    {id, router} = handler.route_handler(path)

    %__MODULE__{
      id: id,
      route_path: router,
      type: handler,
      abs_loc: path,
    }
  end

  def operate_media(media = %__MODULE__{}, target_root) do
    media.type.convert_handler(media.abs_loc, target_root, media.route_path)
      |> case do
        {:ok, dest_path} -> %{media | abs_loc: dest_path, content_replaced: "![](#{media.route_path})"}
        {:error, {:replace, replaced_content}} -> %{media | content_replaced: replaced_content}
      end
  end

  def path_to_media(path, target_root, handler) when is_binary(path) do
    path_to_media(path, handler)
    |> operate_media(target_root)
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
    case Greenhouse.Params.Media.maybe_series(path, "img") do
      {id, {series, id_under_seires, ext}} -> {id, "/image/#{series}/#{id_under_seires}.#{ext}"}
      {id, {id_under_seires, ext}} -> {id, "/image/#{id_under_seires}.#{ext}"}
    end
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

end

defmodule Greenhouse.Params.Media.PDF do
  @behaviour Greenhouse.Params.Media

  @impl true
  def route_handler(path) do
    case Greenhouse.Params.Media.maybe_series(path, "pdf") do
      {id, {series, id_under_seires, ext}} ->
        {id, "/archive/pdf/#{series}/#{id_under_seires}.#{ext}"}

      {id, {id_under_seires, ext}} ->
        {id, "/archive/pdf/#{id_under_seires}.#{ext}"}
    end
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
end

defmodule Greenhouse.Params.Media.Graphviz do
  @behaviour Greenhouse.Params.Media
  require Logger

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
    case Greenhouse.Params.Media.maybe_series(location, "src") do
      {id, {series, id_under_seires, _ext}} -> {id, "/svg/#{series}/#{id_under_seires}.svg"}
      {id, {id_under_seires, _ext}} -> {id, "/svg/#{id_under_seires}.svg"}
    end
  end

  def convert_handler(source_path, target_root_path, router) do
    dest_path = Path.join(target_root_path, router)

    case Runner.execute(source_path) do
      {:ok, svg} -> save_svg(svg, dest_path)
      {:error, {code, reason}} ->
        Logger.warning("DOT #{source_path} build failed with code #{code} and reason #{reason}")

        content = File.read(source_path)

        {:error, {:replace, content}}
    end
  end

  defp save_svg(svg, target_path) do
    File.mkdir_p(Path.dirname(target_path))

    File.write(target_path, svg)
    |> case do
      :ok -> {:ok, target_path}
      err -> err
    end
  end
end
