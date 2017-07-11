defmodule RestAuth.Controller do
  require Logger
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [put_status: 2, halt: 1, put_resp_cookie: 3] 

   @handler Application.get_env(:rest_auth, :handler, :handler_not_set)

  @doc """

  """
  def login(conn, params, opts \\ []) do
    write_cookie = Keyword.get(opts, :write_cookie, false)
    username = Map.get(params, "username", :error)
    raw_password = Map.get(params, "password", :error)

    if raw_password == :error or username == :error do
      conn
      |> put_status(403)
      |> json(%{"error" => "Username and/or password missing"})
      |> halt
    else
      case @handler.load_user_data(username, raw_password) do
        { :ok, payload } ->
          conn = if write_cookie do
            token = payload["token"]
            put_resp_cookie(conn, "x-auth-token", token)#, secure: true)
          else
            conn
          end
          conn
          |> json(%{"data" => payload})
        { :error, reason } ->
          conn
          |> put_status(403)
          |> json(%{"error" => reason})
          |> halt
      end
    end
  end

  def logout(conn, _params, opts \\ []) do
    RestAuth.Utility.get_authority(conn)
    |> @handler.invalidate_token()
    conn = 
      if Keyword.get(opts, :write_cookie, false) do
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
