defmodule RestAuth.ConfigureTest do
  use ExUnit.Case, async: true

  alias RestAuth.Configure

  setup do
    {:ok, conn: Plug.Test.conn(:get, "/")}
  end

  test "requires handler option" do
    assert_raise KeyError, ~r":handler", fn ->
      Configure.init([])
    end
  end

  test "sets handler on the connection", %{conn: conn} do
    conn = call(conn, handler: :handler)
    assert conn.private.rest_auth_handler == :handler
  end

  test "refuses to override handler", %{conn: conn} do
    conn = call(conn, handler: :handler)

    assert_raise ArgumentError, ~r":other_handler", fn ->
      call(conn, handler: :other_handler)
    end
  end

  test "allows setting the same handler twice", %{conn: conn} do
    conn = call(conn, handler: :handler)
    conn = call(conn, handler: :handler)

    assert conn.private.rest_auth_handler == :handler
  end

  defp call(conn, opts) do
    Configure.call(conn, Configure.init(opts))
  end
end
