defmodule Greenhouse.Params.Media do
  defstruct [
    :id,
    :abs_loc,
    :route_handler,   # id => route
    :convert_handler,  # {id, abs_loc} => {:ok, any} | {:error, term}
    :convert_res_handler
  ]

  # @callback route_handler()

  # @callback convert_handler()

  # @callback convert_res_handler()
end

defmodule Greenhouse.Params.Media.Link do
end
