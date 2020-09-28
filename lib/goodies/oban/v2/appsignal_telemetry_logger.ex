defmodule Goodies.Oban.V2.AppsignalTelemetryLogger do
  @moduledoc """
  This module logs Oban v2 Telemetry events on Appsignal.

  To use it, declare on `MyApp.Application.start/1` of the app that is using Oban:
  ```elixir
    :telemetry.attach(
      "oban-job-stop",
      [:oban, :job, :stop],
      &Goodies.Oban.V2.AppsignalTelemetryLogger.handle_event/4,
      nil
    )

    :telemetry.attach(
      "oban-job-exception",
      [:oban, :job, :exception],
      &Goodies.Oban.V2.AppsignalTelemetryLogger.handle_event/4,
      nil
    )
  ```
  """
  alias Appsignal.{Error, Transaction}

  def handle_event([:oban, :job, event], measurement, meta, _)
      when event in [:stop, :exception] do
    transaction = record_event(measurement, meta)

    if event == :exception && meta.attempt >= meta.max_attempts && meta.kind != :exit do
      {reason, message, stack} = normalize_error(meta)
      transaction_module().set_error(transaction, reason, message, stack)
    end

    transaction_module().complete(transaction)
  end

  defp transaction_module do
    Application.fetch_env!(:goodies, :appsignal_transaction_module) || Appsignal.Transaction
  end

  defp record_event(measurement, meta) do
    metadata = %{"id" => meta.id, "queue" => meta.queue, "attempt" => meta.attempt}

    transaction = transaction_module().start(Transaction.generate_id(), :background_job)

    transaction
    |> transaction_module().set_action("#{meta.worker}#perform")
    |> Transaction.set_meta_data(metadata)
    |> Transaction.set_sample_data("params", meta.args)
    |> Transaction.record_event("worker.perform", "", "", measurement.duration, 0)
    |> Transaction.finish()

    transaction
  end

  defp normalize_error(%{error: error, stacktrace: stack}) do
    {reason, message} = Error.metadata(error)
    {inspect(reason), inspect(message, limit: :infinity), stack}
  end
end
