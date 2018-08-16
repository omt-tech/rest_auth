defmodule RestAuth.Authenticate do
  @moduledoc """
  `RestAuth.Authenticate` is used to load user information into conn.

  It will use the configured handler to load the authority struct and
  store it in the connection. The user data can be later accessed using
  functions from `RestAuth.Utility` module.

  # Example

    plug RestAuth.Authenticate

  """
  require Logger

  alias RestAuth.ErrorHandler

  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    case conn.private do
      %{rest_auth_authority: %RestAuth.Authority{} = authority} ->
        Logger.debug "Skipping authentication since #{inspect authority} was already provided in conn"
        conn
      _ ->
        handler = conn.private.rest_auth_handler
        consume_token(conn, handler)
    end
  end

  defp consume_token(conn, handler) do
    case get_token(conn) do
      {conn, token, _from_cookie?} when token in [nil, "deleted"] ->
        anonymous_roles = anonymous_roles(handler)
        Logger.debug "Header X-Auth-Token not found or deleted, storing anonymous user with roles #{inspect anonymous_roles}"
        authority = %RestAuth.Authority{roles: anonymous_roles}
        put_private(conn, :rest_auth_authority, authority)

      {conn, token, from_cookie?} ->
        Logger.debug "Found token #{String.slice(token, 1..8)}...., attempting to load user from cache."
        case handler.load_user_data_from_token(token) do
          {:ok, authority} ->
            Logger.debug "Got authority from token"
            conn
            |> put_private(:rest_auth_authority, authority)

          {:client_outdated, authority} ->
            Logger.debug "Got authority from outdated token"
            conn
            |> put_token_refresh(from_cookie?)
            |> put_private(:rest_auth_authority, authority)

          # All error conditions will halt the plug pipeline
          {:error, reason} ->
            error_handler = ErrorHandler.fetch!(conn)

            error_handler.cannot_authenticate(conn, reason, from_cookie?)
            |> halt() # Ensure halted
        end
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "x-auth-token") do
      [] ->
        Logger.debug "Trying to fetch token from cookie"
        conn = fetch_cookies(conn)
        {conn, Map.get(conn.cookies, "x-auth-token"), true}
      [token | _] ->
        {conn, token, false}
    end
  end

  defp put_token_refresh(conn, from_cookie?) do
    if from_cookie? do
      put_resp_cookie(conn, "x-auth-refresh-token", "true")
    else
      put_resp_header(conn, "x-auth-refresh-token", "true")
    end
  end

  defp anonymous_roles(handler) do
    if function_exported?(handler, :anonymous_roles, 0) do
      handler.anonymous_roles()
    else
      []
    end
  end
end
