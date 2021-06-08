if Code.ensure_loaded?(Appsignal) do
  defmodule Goodies.Oban.V1.AppsignalTelemetryLogger do
    @moduledoc """
    This module logs Oban v1.2 (latest v1 release) Telemetry events on Appsignal.

    To use it, declare on `MyApp.Application.start/1` of the app that is using Oban:
    ```elixir
      :telemetry.attach(
        "oban-failure",
        [:oban, :failure],
        &Goodies.Oban.V1.AppsignalTelemetryLogger.handle_event/4,
        nil
      )

      :telemetry.attach(
        "oban-success",
        [:oban, :success],
        &Goodies.Oban.V1.AppsignalTelemetryLogger.handle_event/4,
        nil
      )
    ```
    """
    alias Appsignal.{Error, Transaction}

    def handle_event([:oban, event], measurement, meta, _) when event in [:success, :failure] do
      transaction = record_event(measurement, meta)

      if event == :failure && meta.attempt >= meta.max_attempts do
        {reason, message, stack} = normalize_error(meta)
        Transaction.set_error(transaction, reason, message, stack)
      end

      Transaction.complete(transaction)
    end

    defp record_event(measurement, meta) do
      metadata = %{"id" => meta.id, "queue" => meta.queue, "attempt" => meta.attempt}

      transaction = Transaction.start(Transaction.generate_id(), :background_job)

      transaction
      |> Transaction.set_action("#{meta.worker}#perform")
      |> Transaction.set_meta_data(metadata)
      |> Transaction.set_sample_data("params", meta.args)
      |> Transaction.record_event("worker.perform", "", "", measurement.duration, 0)
      |> Transaction.finish()

      transaction
    end

    defp normalize_error(error_metadata)

    defp normalize_error(%{kind: :error, error: error, stack: stack, worker: worker}) do
      {"#{worker}Error", stringify(error), stack}
    end

    defp normalize_error(%{kind: :exception, error: error, stack: stack}) do
      {reason, message} = Error.metadata(error)
      {stringify(reason), stringify(message), stack}
    end

    defp stringify(value) do
      if is_binary(value), do: value, else: inspect(value, limit: :infinity)
    end
  end
end
