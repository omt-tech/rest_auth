defmodule RestAuth.Configure do
  @moduledoc """
  Plug responsible for configuring the RestAuth suite on subsequent actions.

  Most other plug-related functionality like `RestAuth.Controller` functions
  or `RestAuth.Restrict` plug require the configure plug to be applied earlier.
  """

  @behaviour Plug

  def init(opts) do
    Keyword.fetch!(opts, :handler)
  end

  def call(conn, handler) do
    case conn.private do
      %{rest_auth_handler: ^handler} ->
        conn
      %{rest_auth_handler: other} ->
        raise ArgumentError, "conflicting `:rest_auth_handler` found: #{inspect other} while trying to configure #{inspect handler}"
      _ ->
        Plug.Conn.put_private(conn, :rest_auth_handler, handler)
    end
  end
end
