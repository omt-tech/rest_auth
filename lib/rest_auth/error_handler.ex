defmodule RestAuth.ErrorHandler do
  @moduledoc """
  Behaviour for providing overridable error handling for RestAuth plugs.

  Configured with `RestAuth.Configure` like:

  ```
  plug RestAuth.Configure,
    handler: YourHandler,
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
  Returns the ErrorHandler from the conn, or raises.
  """
  def fetch!(%Conn{} = conn) do
    case Map.fetch(conn.private, :rest_auth_error_handler) do
      {:ok, error_handler} -> error_handler
      :error -> raise "Unable to fetch the error handler- has the `RestAuth.Configure` plug been used?"
    end
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
