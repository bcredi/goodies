defmodule TestPipeline do
  use Conduit.Plug.Builder
  plug(Goodies.Conduit.Plug.RequestId)
end

defmodule Goodies.Conduit.Plug.RequestIdTest do
  use ExUnit.Case
  doctest Goodies.Conduit.Plug.RequestId

  describe "#call/3" do
    test "keeps message's correlation_id" do
      Logger.metadata(request_id: "123")
      message = TestPipeline.run(%Conduit.Message{correlation_id: "9876543"})

      assert Logger.metadata()[:request_id] == "9876543"
      assert message.correlation_id == "9876543"
    end

    test "sets request_id as message's correlation_id when correlation_id is missing" do
      Logger.metadata(request_id: "123")
      message = TestPipeline.run(%Conduit.Message{correlation_id: nil})

      assert Logger.metadata()[:request_id] == "123"
      assert message.correlation_id == "123"
    end

    test "creates message's correlation_id when correlation_id and request_id are missing" do
      Logger.metadata(request_id: nil)
      message = TestPipeline.run(%Conduit.Message{correlation_id: nil})

      correlation_id = message.correlation_id
      assert {:ok, _uuid} = UUID.info(correlation_id)
      assert Logger.metadata()[:request_id] == correlation_id
    end
  end
end
