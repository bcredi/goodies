defmodule Goodies.Oban.V1.TelemetryLoggerTest do
  use ExUnit.Case

  import Mox

  alias Appsignal.{Transaction, TransactionMock}
  alias Goodies.Oban.V1.TelemetryLogger

  setup :verify_on_exit!

  describe "handle_event/4" do
    test "with success event returns a complete transaction" do
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
        queue: "default",
        worker: "MyApp.SuccessWorker"
      }

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}
      assert TelemetryLogger.handle_event([:oban, :success], measurement, meta, nil) == :ok
    end

    test "with failure event from an exception returns a complete transaction" do
      expect(TransactionMock, :start, 1, fn _, _ ->
        %Transaction{resource: :background_job, id: "01ef700c-3c93-4b52-93d2-e9d5339c7428"}
      end)

      expect(TransactionMock, :set_action, 1, fn _, _ -> :ok end)

      meta = %{
        args: %{"id" => "some id"},
        attempt: 5,
        error: %RuntimeError{message: "runtime error"},
        id: 123,
        kind: :exception,
        max_attempts: 3,
        queue: "default",
        stack: [],
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
      assert TelemetryLogger.handle_event([:oban, :failure], measurement, meta, nil) == :ok
    end

    test "with failure event from an error tuple returns a complete transaction" do
      expect(TransactionMock, :start, 1, fn _, _ ->
        %Transaction{resource: :background_job, id: "01ef700c-3c93-4b52-93d2-e9d5339c7428"}
      end)

      expect(TransactionMock, :set_action, 1, fn _, _ -> :ok end)

      meta = %{
        args: %{"id" => "test"},
        attempt: 3,
        error: %{error: "some error"},
        id: 123,
        kind: :error,
        max_attempts: 3,
        queue: "default",
        stack: [],
        worker: "MyApp.TupleFailureWorker"
      }

      expect(TransactionMock, :set_error, 1, fn _transaction, reason, message, stack ->
        assert reason == "ObanTupleError"
        assert message == "%{error: \"some error\"}"
        assert stack == []
        :ok
      end)

      expect(TransactionMock, :complete, 1, fn _ -> :ok end)

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}
      assert TelemetryLogger.handle_event([:oban, :failure], measurement, meta, nil) == :ok
    end
  end
end
