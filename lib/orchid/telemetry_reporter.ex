defmodule Orchid.TelemetryReporter do
  require Logger

  def handler(_event_name, _measurements, meta, _config) do
    stacktrace =
      if meta[:stacktrace] do
        Exception.format_stacktrace(meta.stacktrace)
      else
        "No stacktrace available"
      end

    Logger.error("""
    [Orchid] Step Exception Captured!
    Step: #{inspect(meta[:impl])}
    Reason: #{inspect(meta[:reason])}
    Stacktrace:
    #{stacktrace}
    """)
  end
end
