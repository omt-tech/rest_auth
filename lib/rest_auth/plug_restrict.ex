defmodule RestAuth.Restrict do
  require Logger
  import Phoenix.Controller, only: [action_name: 1, json: 2]
  import Plug.Conn

  @default_required_roles Application.get_env(:rest_auth, :default_required_roles, [])
  @anonymous_roles Application.get_env(:rest_auth, :anonymous_roles, [])

  @moduledoc """
    `RestAuth.Restrict` is where the magic happens.

    Sample usage:
    ```
    @rest_auth_roles  [
                        {:index, ["user"]},
                        {:create, ["admin"]},
                        {:update, ["admin"]},
                        {:show, ["admin"]},
                        {:delete, ["admin"]}
                       ]
    plug RestAuth.Restrict @rest_auth_roles
    ```

    In this sample usage I have simply listed the roles in an attribute for readability.
    The parameter has to be a keyword list of string lists.
    `{:create, "admin"}` will not work.


  """


  @doc """
  Required initiation method
  """
  def init(default), do: default

  @doc """
      Checks given roles against current user.
    """
  def call(conn, roles) do
    action = action_name(conn)
    case (action in Keyword.keys(roles)) do
      true ->
        Logger.debug "Securing action #{action} against #{inspect roles[action]}"
        conn
        |> consume_token()
        |> check_roles(roles[action])
      false ->
        call(conn)
    end
  end


  @doc """
    If plug is called without for example `roles: ["user", "admin"]`, default role from config will be used
  """
  def call(conn) do
    Logger.debug "Plug called without roles, fetching from handler."
    conn
    |> consume_token()
    |> check_roles(@default_required_roles)
  end


  #Consumes and stores token, 401's if the token is invalid.
  #Also stores handler on conn
   defp consume_token(conn) do
    {conn, auth_token, from_cookie} = case get_req_header(conn, "x-auth-token") do
      [] ->
        Logger.debug "Trying to fetch token from cookie"
        conn = fetch_cookies(conn)
        {conn, Map.get(conn.cookies, "x-auth-token", nil), true}
      [token | _ ] ->
        {conn, token, false}
    end
    case auth_token do
      token when is_nil(token) or token == "deleted" ->
        Logger.debug "Header X-Auth-Token not found or deleted, storing anonymous user with roles #{inspect @anonymous_roles}"
        conn
        |> put_private(:rest_auth_authority, %RestAuth.Authority{})
      token ->
        Logger.debug "Found token #{String.slice(token, 1..8)}...., attempting to load user from cache."
        case handler().load_user_data_from_token(token) do
          {:ok, authority} ->
            Logger.debug "Got authority from token"
            conn
            |> put_private(:rest_auth_authority, authority)
          #Both error conditions will halt the plug pipeline
          {:error, reason}->
            #If an invalid token comes from cookie, set it to deleted
            conn = if from_cookie, do: put_resp_cookie(conn, "x-auth-token", "deleted"), else: conn
            conn
            |> put_status(401)
            |> json(%{ "error" => reason})
            |> halt
        end
    end
  end

  #If required roles is :permit_all we allow everything by default
  defp check_roles(conn, :permit_all) do
    Logger.debug ":permit_all endpoint, allowing access"
    conn
  end


  #Does the actual role check, utilizing `RestAuth.Utility.if_any_granted/1`
  defp check_roles(conn, required_roles) do
    case  RestAuth.Utility.is_any_granted?(conn, required_roles) do
      false ->
        case RestAuth.Utility.is_anonymous?(conn) do
          true ->
            conn
            |> put_status(401)
            |> json(%{"error" => "not authenticated"})
            |> halt()
          false ->
            conn
            |> put_status(403)
            |> json(%{"error" => "you do not have access to this resource"})
            |> halt()
        end
      true ->
        conn
    end
  end

  defp handler() do
    Application.get_env(:rest_auth, :handler, RestAuth.DummyHandler)
  end

end
