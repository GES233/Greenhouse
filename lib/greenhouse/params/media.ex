defmodule Greenhouse.Params.Media do
  @type t :: %__MODULE__{
    id: binary() | atom(),
    abs_loc: binary(),
    type: module()
  }
  defstruct [
    :id,
    :abs_loc,
    :type
  ]

  # @doc ""
  # @callback route_handler(id :: binary()) :: binary()

  # @callback convert_handler(id :: binary(), abs_loc :: binary()) :: :ok | {:error, term()}

  # @callback convert_res_handler()
end

defmodule Greenhouse.Params.Media.Link do
end
