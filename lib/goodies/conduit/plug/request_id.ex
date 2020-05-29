defmodule Goodies.Conduit.Plug.RequestId do
  use Conduit.Plug.Builder
  require Logger

  @moduledoc """
  Assigns the `Logger.metadata()[:request_id]` for the correlation ID of the message if one isn't present
  and always assigns it to the logger metadata.

  ## Examples

      iex> defmodule MyPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Goodies.Conduit.Plug.RequestId
      iex> end
      iex>
      iex> Logger.metadata(request_id: "123")
      iex> message = MyPipeline.run(%Conduit.Message{})
      iex> message.correlation_id == Logger.metadata()[:request_id]
      true

      iex> defmodule MyPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Goodies.Conduit.Plug.RequestId
      iex> end
      iex>
      iex> Logger.metadata(request_id: "123")
      iex> message = MyPipeline.run(%Conduit.Message{correlation_id: "123456"})
      iex> Logger.metadata()[:request_id] == "123456" and message.correlation_id == "123456"
      true

  """

  @doc """
  Assigns the `Logger.metadata()[:request_id]` for the correlation ID of the message if one isn't present
  and always assigns it to the logger metadata.
  """
  def call(message, next, _opts) do
    request_id = Logger.metadata()[:request_id]

    message =
      if is_nil(request_id),
        do: message,
        else: put_new_correlation_id(message, request_id)

    message
    |> put_logger_metadata()
    |> next.()
  end

  defp put_logger_metadata(message) do
    Logger.metadata(request_id: message.correlation_id)
    message
  end
end
