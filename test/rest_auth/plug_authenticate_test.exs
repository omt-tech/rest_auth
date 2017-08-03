defmodule RestAuth.AuthenticateTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Phoenix.ConnTest

  setup do
    conn =
      Plug.Test.conn(:get, "/")
      |> RestAuth.Test.configure(handler: RestAuth.TestHandler)
    {:ok, conn: conn}
  end

  test "passes through with authority set in conn", %{conn: conn} do
    Process.put(:load_user_data_1, fn nil ->
      {:ok, %RestAuth.Authority{token: "abc"}}
    end)
    conn = RestAuth.Test.authenticate_conn(conn, nil)

    assert conn == call(conn)
  end

  test "consumes token from header and succeeds", %{conn: conn} do
    unique_id = System.unique_integer()
    Process.put(:load_user_data_from_token, fn "foobarbaz" ->
      {:ok, %RestAuth.Authority{user_id: unique_id}}
    end)
    conn = put_req_header(conn, "x-auth-token", "foobarbaz")

    conn = call(conn)
    assert RestAuth.Utility.get_authority(conn).user_id == unique_id
  end

  test "consumes token from header and succeeds outdated", %{conn: conn} do
    unique_id = System.unique_integer()
    Process.put(:load_user_data_from_token, fn "foobarbaz" ->
      {:client_outdated, %RestAuth.Authority{user_id: unique_id}}
    end)
    conn = put_req_header(conn, "x-auth-token", "foobarbaz")

    conn = call(conn)
    assert RestAuth.Utility.get_authority(conn).user_id == unique_id
    assert get_resp_header(conn, "x-auth-refresh-token") == ["true"]
  end

  test "consumes token from header and fails", %{conn: conn} do
    Process.put(:load_user_data_from_token, fn "foobarbaz" ->
      {:error, "some error"}
    end)
    conn = put_req_header(conn, "x-auth-token", "foobarbaz")

    conn = call(conn)
    assert conn.halted
    assert %{"error" => "some error"} = json_response(conn, 401)
  end

  test "consumes token from cookie and succeeds", %{conn: conn} do
    unique_id = System.unique_integer()
    Process.put(:load_user_data_from_token, fn "foobarbaz" ->
      {:ok, %RestAuth.Authority{user_id: unique_id}}
    end)
    conn = put_req_cookie(conn, "x-auth-token", "foobarbaz")

    conn = call(conn)
    assert RestAuth.Utility.get_authority(conn).user_id == unique_id
  end

  test "consumes token from cookie and succeeds outdated", %{conn: conn} do
    unique_id = System.unique_integer()
    Process.put(:load_user_data_from_token, fn "foobarbaz" ->
      {:client_outdated, %RestAuth.Authority{user_id: unique_id}}
    end)
    conn = put_req_cookie(conn, "x-auth-token", "foobarbaz")

    conn = call(conn)
    assert RestAuth.Utility.get_authority(conn).user_id == unique_id
    assert conn.resp_cookies["x-auth-refresh-token"] == %{value: "true"}
  end

  test "consumes token from cookie and fails", %{conn: conn} do
    Process.put(:load_user_data_from_token, fn "foobarbaz" ->
      {:error, "some error"}
    end)
    conn = put_req_cookie(conn, "x-auth-token", "foobarbaz")

    conn = call(conn)
    assert conn.halted
    assert %{"error" => "some error"} = json_response(conn, 401)
    assert conn.resp_cookies["x-auth-token"] == %{value: "deleted"}
  end

  def call(conn, opts \\ []) do
    RestAuth.Authenticate.call(conn, RestAuth.Authenticate.init(opts))
  end
end
