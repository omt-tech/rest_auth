defmodule RestAuth.Configure do
  @moduledoc """
  Plug responsible for configuring the RestAuth suite on subsequent actions.

  Most other plug-related functionality like `RestAuth.Controller` functions
  or `RestAuth.Restrict` plug require the configure plug to be applied earlier.

  A `:handler` must be provided, while an `:error_handler` may optionally be
  provided.
  """

  @behaviour Plug

  alias RestAuth.ErrorHandler

  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    error_handler = Keyword.get(opts, :error_handler, ErrorHandler.Default)
    {handler, error_handler}
  end

  def call(conn, {handler, error_handler}) do
    case conn.private do
      %{rest_auth_handler: ^handler, rest_auth_error_handler: ^error_handler} ->
        conn

      %{rest_auth_handler: other, rest_auth_error_handler: ^error_handler} ->
        raise ArgumentError, "conflicting `:rest_auth_handler` found: #{inspect other} while trying to configure #{inspect handler}"

      %{rest_auth_handler: ^handler, rest_auth_error_handler: other} ->
        raise ArgumentError, "conflicting `:rest_auth_handler` found: #{inspect other} while trying to configure #{inspect handler}"

      %{rest_auth_handler: other_h, rest_auth_error_handler: other_eh} ->
        raise ArgumentError, "conflicting `:rest_auth_handler` and `:rest_auth_error_handler` found: #{inspect(other_h)} and #{inspect(other_eh)} while trying to configure #{inspect(handler)} and #{inspect(error_handler)}"

      _ ->
        conn
        |> Plug.Conn.put_private(:rest_auth_handler, handler)
        |> Plug.Conn.put_private(:rest_auth_error_handler, error_handler)
    end
  end
end
