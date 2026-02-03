defmodule Greenhouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :telemetry.attach(
      "orchid-error-logger",
      [:orchid, :step, :exception],
      &Orchid.TelemetryReporter.handler/4,
      nil
    )

    children = [
      {Greenhouse.Storage, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Greenhouse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
