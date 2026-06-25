defmodule Greenhouse.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Greenhouse.Storage, []}
    ]

    opts = [strategy: :one_for_one, name: Greenhouse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
