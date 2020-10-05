defmodule Goodies.Oban.V2.AppsignalTelemetryLoggerTest do
  use ExUnit.Case
  import Mock

  alias Appsignal.Transaction
  alias Goodies.Oban.V2.AppsignalTelemetryLogger

  defmodule Oban.PerformError do
    defexception [:message, :reason]

    @impl Exception
    def exception({worker, reason}) do
      message = "#{to_string(worker)} failed with #{inspect(reason)}"

      %__MODULE__{message: message, reason: reason}
    end
  end

  describe "handle_event/4" do
    test "with stop (success) event returns a complete transaction" do
      meta = %{
        args: %{"id" => "some id"},
        attempt: 1,
        id: 123,
        max_attempts: 3,
        prefix: "public",
        queue: "default",
        worker: "MyApp.SuccessWorker"
      }

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

      with_mock(Transaction, [:passthrough],
        start: fn id, resource -> %Transaction{id: id, resource: resource} end,
        set_action: fn _, _ -> :ok end,
        complete: fn _ -> :ok end
      ) do
        assert AppsignalTelemetryLogger.handle_event([:oban, :job, :stop], measurement, meta, nil) ==
                 :ok
      end
    end

    test "with exception event from an exception returns a complete transaction" do
      meta = %{
        args: %{"id" => "some id"},
        attempt: 3,
        error: %RuntimeError{message: "runtime error"},
        id: 123,
        kind: :error,
        max_attempts: 3,
        prefix: "public",
        queue: "default",
        stacktrace: [],
        worker: "MyApp.ExceptionFailureWorker"
      }

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

      with_mock(Transaction, [:passthrough],
        start: fn _, _ ->
          %Transaction{resource: :background_job, id: "01ef700c-3c93-4b52-93d2-e9d5339c7428"}
        end,
        set_action: fn _, _ -> :ok end,
        set_error: fn _, "\"RuntimeError\"", "\"runtime error\"", [] -> :ok end,
        complete: fn _ -> :ok end
      ) do
        assert AppsignalTelemetryLogger.handle_event(
                 [:oban, :job, :exception],
                 measurement,
                 meta,
                 nil
               ) ==
                 :ok
      end
    end

    test "with exception event from an error tuple returns a complete transaction" do
      meta = %{
        args: %{"id" => "test"},
        attempt: 3,
        error: %Oban.PerformError{
          message: "MyApp.TupleFailureWorker failed with {:error, \"some error\"}",
          reason: {:error, "some error"}
        },
        id: 123,
        kind: :error,
        max_attempts: 3,
        prefix: "public",
        queue: "default",
        stacktrace: [],
        worker: "MyApp.TupleFailureWorker"
      }

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

      with_mock(Transaction, [:passthrough],
        start: fn _, _ ->
          %Transaction{resource: :background_job, id: "01ef700c-3c93-4b52-93d2-e9d5339c7428"}
        end,
        set_action: fn _, _ -> :ok end,
        set_error: fn _,
                      "\"Goodies.Oban.V2.AppsignalTelemetryLoggerTest.Oban.PerformError\"",
                      "\"MyApp.TupleFailureWorker failed with {:error, \\\"some error\\\"}\"",
                      [] ->
          :ok
        end,
        complete: fn _ -> :ok end
      ) do
        assert AppsignalTelemetryLogger.handle_event(
                 [:oban, :job, :exception],
                 measurement,
                 meta,
                 nil
               ) ==
                 :ok
      end
    end
  end
end
