defmodule RestAuth.Controller do
  require Logger
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [put_status: 2, halt: 1, put_resp_cookie: 3] 

  @handler Application.get_env(:rest_auth, :handler, RestAuth.DummyHandler)
  @write_cookie Application.get_env(:rest_auth, :write_cookie, false)

  @moduledoc """
  Generic controller handling login and logout.
  """

  @doc """
  Call this function from your authentication controller.
  It will write the token to a cookie if `:write_cookie` is set to 
  `true` in the `:rest_auth` configuration. Defaults to false

  ```
  def login(conn, params) do
    RestAuth.Controller.login(conn, params, write_cookie: true)
  end
  ```
  """
  def login(conn, params) do
    username = Map.get(params, "username", :error)
    raw_password = Map.get(params, "password", :error)

    if raw_password == :error or username == :error do
      conn
      |> put_status(403)
      |> json(%{"error" => "Username and/or password missing"})
      |> halt
    else
      case @handler.load_user_data(username, raw_password) do
        { :ok, authority = %RestAuth.Authority{} } ->
          conn = if @write_cookie do
            put_resp_cookie(conn, "x-auth-token", authority.token)#, secure: true)
          else
            conn
          end
          conn
          |> json(%{"data" => authority})
        { :error, reason } ->
          conn
          |> put_status(403)
          |> json(%{"error" => reason})
          |> halt
      end
    end
  end

  @doc """
  Call this function from your authentication controller.
  It will write the token to a cookie if `:write_cookie` is set to 
  `true` in the `:rest_auth` configuration. Defaults to false

  ```
  def logout(conn, params) do
    RestAuth.Controller.logout(conn, params)
  end
  ```
  
  """
  def logout(conn) do
    RestAuth.Utility.get_authority(conn)
    |> @handler.invalidate_token()
    conn = 
      if @write_cookie do
        put_resp_cookie(conn, "x-auth-token", "deleted")
      else
        conn
      end
    conn
    |> put_status(200)
    |> json(%{"success" => "logged out"})
    |> halt
  end


end
