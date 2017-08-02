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
    Plug.Conn.put_private(conn, :rest_auth_handler, handler)
  end
end
