defmodule RestAuth.ControllerTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  alias RestAuth.Controller

  setup do
    conn = Plug.Test.conn(:get, "/")
    {:ok, conn: RestAuth.Test.configure(conn, handler: RestAuth.TestHandler)}
  end

  describe "login" do
    test "without username issues error", %{conn: conn} do
      params = %{"password" => "123"}
      resp = Controller.login(conn, params)

      assert %{"error" => _} = json_response(resp, 403)
      assert resp.halted
    end

    test "without password issues error", %{conn: conn} do
      params = %{"username" => "123"}
      resp = Controller.login(conn, params)

      assert %{"error" => _} = json_response(resp, 403)
      assert resp.halted
    end

    test "loads data using the handler", %{conn: conn} do
      Process.put(:load_user_data_2, fn "foobar", "barfoo" ->
        {:ok, %RestAuth.Authority{token: "abc"}}
      end)
      params = %{"username" => "foobar", "password" => "barfoo"}
      resp = Controller.login(conn, params)

      assert %{"data" => %{"token" => "abc"}} = json_response(resp, 200)
    end

    test "responds with error from the handler", %{conn: conn} do
      Process.put(:load_user_data_2, fn "foobar", "barfoo" ->
        {:error, "test error"}
      end)
      params = %{"username" => "foobar", "password" => "barfoo"}
      resp = Controller.login(conn, params)

      assert %{"error" => "test error"} = json_response(resp, 403)
      assert resp.halted
    end

    test "writes cookie if handler is configured to do so", %{conn: conn} do
      Process.put(:write_cookie?, true)
      Process.put(:load_user_data_2, fn "foobar", "barfoo" ->
        {:ok, %RestAuth.Authority{token: "abc"}}
      end)
      params = %{"username" => "foobar", "password" => "barfoo"}
      resp = Controller.login(conn, params)

      assert %{value: "abc"} == resp.resp_cookies["x-auth-token"]
    end
  end

  describe "logout" do
    setup %{conn: conn} do
      Process.put(:load_user_data_1, fn _ ->
        {:ok, %RestAuth.Authority{token: "abc"}}
      end)
      auth_conn = RestAuth.Test.authenticate_conn(conn, nil)
      {:ok, auth_conn: auth_conn}
    end

    test "requires conn to be authenticated", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        Controller.logout(conn)
      end
    end

    test "calls invalidate_token", %{auth_conn: conn} do
      Process.put(:invalidate_token, fn %RestAuth.Authority{token: "abc"} ->
        send(self(), :token_invalidated)
        :ok
      end)

      Controller.logout(conn)

      assert_received :token_invalidated
    end

    test "responds with success", %{auth_conn: conn} do
      Process.put(:invalidate_token, fn _ -> :ok end)

      resp = Controller.logout(conn)

      assert %{"success" => "logged out"} = json_response(resp, 200)
      assert resp.halted
    end

    test "writes cookie if handler is configured to do so", %{auth_conn: conn} do
      Process.put(:invalidate_token, fn _ -> :ok end)
      Process.put(:write_cookie?, true)

      resp = Controller.logout(conn)

      assert %{value: "deleted"} == resp.resp_cookies["x-auth-token"]
    end
  end
end
