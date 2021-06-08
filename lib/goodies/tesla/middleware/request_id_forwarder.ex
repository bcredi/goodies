if Code.ensure_loaded?(Tesla) do
  defmodule Goodies.Tesla.Middleware.RequestIdForwarder do
    @moduledoc """
    Tesla middleware to forward *x-request-id* header to others services.

    Assigns `Logger.metadata()[:request_id]` to *x-request-id* header.
    """

    @behaviour Tesla.Middleware

    require Logger

    @impl Tesla.Middleware
    def call(%Tesla.Env{} = env, next, _opts) do
      request_id = Logger.metadata()[:request_id]

      if is_binary(request_id) do
        env
        |> Tesla.put_header("x-request-id", request_id)
        |> Tesla.run(next)
      else
        Tesla.run(env, next)
      end
    end
  end
end
