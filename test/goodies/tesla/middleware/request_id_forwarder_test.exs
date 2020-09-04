defmodule Goodies.Tesla.Middleware.RequestIdForwarderTest do
  use ExUnit.Case
  alias Tesla.Env

  @middleware Goodies.Tesla.Middleware.RequestIdForwarder

  describe "#call/3" do
    test "set header when request-id is defined in logger metadata" do
      Logger.metadata(request_id: "123")
      {:ok, env} = @middleware.call(%Env{}, [], [])

      {"x-request-id", request_id} =
        Enum.find(env.headers, fn {key, _} -> key == "x-request-id" end)

      assert request_id == "123"
    end

    test "do nothing when request-id is not defined in logger metadata" do
      {:ok, env} = @middleware.call(%Env{}, [], [])
      assert env.headers == []
    end
  end
end
