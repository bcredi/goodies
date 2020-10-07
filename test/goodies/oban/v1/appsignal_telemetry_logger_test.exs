defmodule Goodies.Oban.V1.AppsignalTelemetryLoggerTest do
  use ExUnit.Case
  import Mock

  alias Appsignal.Transaction
  alias Goodies.Oban.V1.AppsignalTelemetryLogger

  describe "handle_event/4" do
    test "with success event returns a complete transaction" do
      meta = %{
        args: %{"id" => "some id"},
        attempt: 1,
        id: 123,
        max_attempts: 3,
        queue: "default",
        worker: "MyApp.SuccessWorker"
      }

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

      with_mock(Transaction, [:passthrough], complete: fn _ -> :ok end) do
        assert AppsignalTelemetryLogger.handle_event([:oban, :success], measurement, meta, nil) ==
                 :ok

        assert called(Transaction.start(:_, :_))
        assert called(Transaction.complete(:_))
      end
    end

    test "with failure event from an exception returns a complete transaction" do
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

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

      with_mock(Transaction, [:passthrough], complete: fn _ -> :ok end) do
        assert AppsignalTelemetryLogger.handle_event([:oban, :failure], measurement, meta, nil) ==
                 :ok

        assert called(Transaction.start(:_, :_))
        assert called(Transaction.set_error(:_, "RuntimeError", "runtime error", []))
        assert called(Transaction.complete(:_))
      end
    end

    test "with failure event from an error tuple returns a complete transaction" do
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

      measurement = %{duration: Time.from_erl!({22, 30, 20}).second * 1000 * 1000}

      with_mock(Transaction, [:passthrough], complete: fn _ -> :ok end) do
        assert AppsignalTelemetryLogger.handle_event([:oban, :failure], measurement, meta, nil) ==
                 :ok

        assert called(Transaction.start(:_, :_))

        assert called(
                 Transaction.set_error(
                   :_,
                   "MyApp.TupleFailureWorkerError",
                   "%{error: \"some error\"}",
                   []
                 )
               )

        assert called(Transaction.complete(:_))
      end
    end
  end
end
