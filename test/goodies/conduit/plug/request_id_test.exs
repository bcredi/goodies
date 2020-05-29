defmodule TestPipeline do
  use Conduit.Plug.Builder
  plug(Goodies.Conduit.Plug.RequestId)
end

defmodule Goodies.Conduit.Plug.RequestIdTest do
  use ExUnit.Case
  doctest Goodies.Conduit.Plug.RequestId

  describe "#call/3" do
    test "should set the correlation_id when request_id is defined and the message hasn't correlation id" do
      Logger.metadata(request_id: "123")
      message = TestPipeline.run(%Conduit.Message{})
      assert "123" == message.correlation_id
    end

    test "should not set the correlation_id when the message already has a correlation_id" do
      Logger.metadata(request_id: "123")
      message = TestPipeline.run(%Conduit.Message{correlation_id: "9876543"})
      assert "9876543" == Logger.metadata()[:request_id]
      assert "9876543" == message.correlation_id
    end

    test "should set Logger request_id when correlation_id is defined" do
      Logger.metadata(request_id: nil)
      message = TestPipeline.run(%Conduit.Message{correlation_id: "9876543"})
      assert "9876543" == Logger.metadata()[:request_id]
      assert "9876543" == message.correlation_id
    end
  end
end
