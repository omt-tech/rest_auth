defmodule RestAuth.ErrorHandler do
  @moduledoc """
  Behaviour for providing overridable error handling for RestAuth plugs.

  Set in config like:
  ```elixir
  config :rest_auth,
    error_handler: YourErrorHandler
  ```
  """

  alias Plug.Conn

  import Plug.Conn

  @doc """
  Triggered when there is an error authenticating a client.

  Used in:
    `RestAuth.Authenticate`.
  """
  @callback cannot_authenticate(conn :: Conn.t(), reason :: any, from_cookie? :: boolean) :: Conn.t()

  @doc """
  Triggered when a client is unauthenticated.

  Used in:
    `RestAuth.Restrict`.
  """
  @callback unauthenticated(conn :: Conn.t()) :: Conn.t()

  @doc """
  Triggered when a client is unauthorized.

  Used in:
    `RestAuth.Restrict`.
  """
  @callback unauthorized(conn :: Conn.t()) :: Conn.t()

  # Helpers

  @doc """
  Returns the ErrorHandler set in config, or the provided default.
  """
  def from_config_or(default) do
    Application.get_env(:rest_auth, :error_handler, default)
  end

  @doc """
  Deletes the `x-auth-token` cookie.

  For use when an invalid token is provided by a cookie.
  """
  def clean_cookie(conn, true) do
    put_resp_cookie(conn, "x-auth-token", "deleted")
  end

  def clean_cookie(conn, false), do: conn
end
