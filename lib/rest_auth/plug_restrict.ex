defmodule RestAuth.Restrict do
  @moduledoc """
  `RestAuth.Restrict` is used to secure endpoints.

  # Example

      @rest_auth_roles  [
        {:index, ["user"]},
        {:create, ["admin"]},
        {:update, ["admin"]},
        {:show, ["admin"]},
        {:delete, ["admin"]},
        {:ping, :permit_all}
      ]
      plug RestAuth.Restrict @rest_auth_roles

  In this sample usage I have simply listed the roles in an attribute for readability.
  The parameter has to be a keyword list of string lists or atom `:permit_all`.

  """
  require Logger
  import Phoenix.Controller, only: [action_name: 1, json: 2]
  import Plug.Conn

  @doc """
  Required initiation method
  """
  def init(roles) do
    Map.new(roles)
  end

  @doc """
  Checks given roles against current user.
  """
  def call(conn, roles) do
    action = action_name(conn)
    handler = conn.private.rest_auth_handler
    case Map.fetch(roles, action) do
      {:ok, action_roles} ->
        Logger.debug "Securing action #{action} against #{inspect action_roles}"
        conn
        |> consume_token(handler)
        |> check_roles(action_roles)
      :error ->
        Logger.debug "Plug called without roles for #{action}, fetching from handler"
        conn
        |> consume_token(handler)
        |> check_roles(handler.default_required_roles())
    end
  end

  defp consume_token(conn, handler) do
    case conn.private do
      %{rest_auth_authority: %RestAuth.Authority{} = authority} ->
        Logger.debug "Skipping authentication since #{inspect authority} was already provided in conn"
        conn
      _ ->
        do_consume_token(conn, handler)
    end
  end

  # Consumes and stores token, 401's if the token is invalid.
  defp do_consume_token(conn, handler) do
    case get_token(conn) do
      {conn, token, _from_cookie?} when token in [nil, "deleted"] ->
        anonymous_roles = handler.anonymous_roles()
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
            conn
            |> put_resp_header("x-auth-refresh-token", true)
            |> put_private(:rest_auth_authority, authority)
          # All error conditions will halt the plug pipeline
          {:error, reason} ->
            conn
            |> clean_cookie(from_cookie?)
            |> put_status(401)
            |> json(%{"error" => reason})
            |> halt
        end
    end
  end

  # If an invalid token comes from cookie, set it to deleted
  defp clean_cookie(conn, from_cookie?) do
    if from_cookie? do
      put_resp_cookie(conn, "x-auth-token", "deleted")
    else
      conn
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "x-auth-token") do
      [] ->
        Logger.debug "Trying to fetch token from cookie"
        conn = fetch_cookies(conn)
        {conn, Map.get(conn.cookies, "x-auth-token", nil), true}
      [token | _] ->
        {conn, token, false}
    end
  end

  defp check_roles(conn, :permit_all) do
    Logger.debug ":permit_all endpoint, allowing access"
    conn
  end

  defp check_roles(conn, required_roles) do
    cond do
      RestAuth.Utility.is_any_granted?(conn, required_roles) ->
        conn
      RestAuth.Utility.is_anonymous?(conn) ->
        conn
        |> put_status(401)
        |> json(%{"error" => "not authenticated"})
        |> halt()
      true ->
        conn
        |> put_status(403)
        |> json(%{"error" => "you do not have access to this resource"})
        |> halt()
    end
  end
end
