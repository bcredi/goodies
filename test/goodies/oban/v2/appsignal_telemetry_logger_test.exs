defmodule Goodies.Oban.V2.AppsignalTelemetryLoggerTest do
  use ExUnit.Case

  import Mox

  alias Appsignal.{Transaction, TransactionMock}
  alias Goodies.Oban.V2.AppsignalTelemetryLogger

  setup :verify_on_exit!

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
      expect(TransactionMock, :start, 1, fn id, resource ->
        %Transaction{id: id, resource: resource}
      end)

      expect(TransactionMock, :set_action, 1, fn _, _ -> :ok end)
      expect(TransactionMock, :complete, 1, fn _ -> :ok end)

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

      assert AppsignalTelemetryLogger.handle_event([:oban, :job, :stop], measurement, meta, nil) ==
               :ok
    end

    test "with exception event from an exception returns a complete transaction" do
      expect(TransactionMock, :start, 1, fn _, _ ->
        %Transaction{resource: :background_job, id: "01ef700c-3c93-4b52-93d2-e9d5339c7428"}
      end)

      expect(TransactionMock, :set_action, 1, fn _, _ -> :ok end)

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

      expect(TransactionMock, :set_error, 1, fn _transaction, reason, message, stack ->
        assert reason == "\"RuntimeError\""
        assert message == "\"runtime error\""
        assert stack == []
        :ok
      end)

      expect(TransactionMock, :complete, 1, fn _ -> :ok end)

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

      assert AppsignalTelemetryLogger.handle_event(
               [:oban, :job, :exception],
               measurement,
               meta,
               nil
             ) ==
               :ok
    end

    test "with exception event from an error tuple returns a complete transaction" do
      expect(TransactionMock, :start, 1, fn _, _ ->
        %Transaction{resource: :background_job, id: "01ef700c-3c93-4b52-93d2-e9d5339c7428"}
      end)

      expect(TransactionMock, :set_action, 1, fn _, _ -> :ok end)

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

      expect(TransactionMock, :set_error, 1, fn _transaction, reason, message, stack ->
        assert reason == "\"Goodies.Oban.V2.AppsignalTelemetryLoggerTest.Oban.PerformError\""
        assert message == "\"MyApp.TupleFailureWorker failed with {:error, \\\"some error\\\"}\""
        assert stack == []
        :ok
      end)

      expect(TransactionMock, :complete, 1, fn _ -> :ok end)

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

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
