defmodule RestAuth.Controller do
  @moduledoc """
  Generic controller handling login and logout.
  """

  require Logger
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [put_status: 2, halt: 1, put_resp_cookie: 3] 

  @doc """
  Call this function from your authentication controller.

  It will write the token to a cookie if handler is configured to write cookies.

  # Example

      def login(conn, params) do
        RestAuth.Controller.login(conn, params, write_cookie: true)
      end

  """
  def login(conn, %{"username" => username, "password" => raw_password}) do
    handler = conn.private.rest_auth_handler
    case handler.load_user_data(username, raw_password) do
      {:ok, authority = %RestAuth.Authority{}} ->
        conn
        |> write_cookie(authority.token, handler)
        |> json(%{"data" => authority})
      {:error, reason} ->
        conn
        |> put_status(403)
        |> json(%{"error" => reason})
        |> halt
    end
  end
  def login(conn, _params) do
    conn
    |> put_status(403)
    |> json(%{"error" => "Username and/or password missing"})
    |> halt
  end

  @doc """
  Call this function from your authentication controller.

  It will write the token to a cookie if handler is set to write cookies.

  # Example

      def logout(conn, params) do
        RestAuth.Controller.logout(conn)
      end

  """
  def logout(conn) do
    handler = conn.private.rest_auth_handler
    auth = RestAuth.Utility.get_authority(conn)
    handler.invalidate_token(auth)
    conn
    |> write_cookie("deleted", handler)
    |> put_status(200)
    |> json(%{"success" => "logged out"})
    |> halt
  end

  defp write_cookie(conn, value, handler) do
    if handler.write_cookie?() do
      put_resp_cookie(conn, "x-auth-token", value)
    else
      conn
    end
  end
end
