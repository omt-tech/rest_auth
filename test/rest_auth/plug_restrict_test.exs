defmodule RestAuth.RestrictTest do
  use ExUnit.Case, async: true
  @moduletag report: [:authority]

  import Phoenix.ConnTest
  import Plug.Conn

  setup %{authority: authority} do
    Process.put(:load_user_data_1, fn nil ->
      {:ok, authority}
    end)
    conn =
      build_conn()
      |> RestAuth.Test.configure(handler: RestAuth.TestHandler)
      |> put_action(:action)
    auth_conn = RestAuth.Test.authenticate_conn(conn, nil)
    {:ok, conn: conn, auth_conn: auth_conn}
  end

  @tag authority: %RestAuth.Authority{}
  test "on unauthenticated conn", %{conn: conn} do
    assert_raise ArgumentError, fn ->
      call(conn, [])
    end
  end

  describe "anonymous authority" do
    @describetag authority: %RestAuth.Authority{anonymous: true, roles: ["anonymous"]}

    test "authenticated when roles match", %{auth_conn: conn} do
      assert conn == call(conn, [action: ["anonymous"]])
    end

    test "unauthenticated when roles don't match", %{auth_conn: conn} do
      conn = call(conn, [action: ["some role"]])

      assert %{"error" => "not authenticated"} = json_response(conn, 401)
      assert conn.halted
    end
  end

  describe "with explicit roles" do
    @describetag authority: %RestAuth.Authority{anonymous: false, roles: ["abc"]}

    test "authenticated when roles match", %{auth_conn: conn} do
      assert conn == call(conn, [action: ["abc", "def"]])
    end

    test "unauthorized when roles don't match", %{auth_conn: conn} do
      conn = call(conn, [action: ["def"]])

      assert %{"error" => "you do not have access to this resource"} = json_response(conn, 403)
      assert conn.halted
    end
  end

  describe "with default roles" do
    @describetag authority: %RestAuth.Authority{anonymous: false, roles: ["abc"]}

    test "authenticated when roles match", %{auth_conn: conn} do
      Process.put(:default_required_roles, ["abc"])
      assert conn == call(conn, [])
    end

    test "unauthorized when roles don't match", %{auth_conn: conn} do
      Process.put(:default_required_roles, ["def"])
      conn = call(conn, [])

      assert %{"error" => "you do not have access to this resource"} = json_response(conn, 403)
      assert conn.halted
    end
  end

  def call(conn, opts) do
    RestAuth.Restrict.call(conn, RestAuth.Restrict.init(opts))
  end

  # This is using private implementation of phoenix, which is not good.
  # Unfortunately there's no easy way to set it without setting up a whole
  # phoenix controller, which is a bit too much
  defp put_action(conn, action) do
    put_private(conn, :phoenix_action, action)
  end
end
