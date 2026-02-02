defmodule Greenhouse.Steps.Helpers do
  @orchid_internal_keys [
    :__orchid_workflow_ctx__,
    :__reporter_ctx__
  ]

  def drop_orchid_native(opts) do
    Keyword.drop(opts, @orchid_internal_keys)
  end
end
