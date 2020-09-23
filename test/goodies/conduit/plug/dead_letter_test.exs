defmodule Goodies.Conduit.Plug.DeadLetterTest do
  use ExUnit.Case
  alias Conduit.Message

  defmodule Broker do
    def publish(message, name, opts) do
      send(self(), {:publish, name, message, opts})
    end
  end

  describe "when the message is nacked" do
    defmodule NackedDeadLetter do
      use Conduit.Subscriber
      plug(Goodies.Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error)

      def process(message, _) do
        nack(message)
      end
    end

    test "it publishes the message to the dead letter destination and acks the message" do
      assert %Message{status: :ack} = NackedDeadLetter.run(%Message{})
      assert_received {:publish, :error, %Message{}, broker: Broker, publish_to: :error}
    end
  end

  describe "when the message has errored" do
    defmodule ErroredDeadLetter do
      use Conduit.Subscriber
      plug(Goodies.Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error)

      def process(_message, _opts), do: raise("failure")
    end

    test "it publishes the message to the dead letter destination and acks the message" do
      assert %Message{status: :ack} = ErroredDeadLetter.run(%Message{})
      assert_received {:publish, :error, %Message{} = message, broker: Broker, publish_to: :error}
      assert Message.get_header(message, "exception") =~ "failure"
    end
  end

  describe "when the message is successful" do
    defmodule AckDeadLetter do
      use Conduit.Subscriber
      plug(Goodies.Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error)

      def process(message, _opts), do: message
    end

    test "it does not send a dead letter" do
      assert %Message{status: :ack} = AckDeadLetter.run(%Message{})
      refute_received {:publish, _, %Message{}, _}
    end
  end
end
