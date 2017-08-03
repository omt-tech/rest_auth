defmodule RestAuth.RestrictTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Plug.Conn

  setup do
    conn =
      Plug.Test.conn(:get, "/")
      |> RestAuth.Test.configure(handler: RestAuth.TestHandler)
      |> put_action(:action)
    {:ok, conn: conn}
  end

  # test "passes through with authority set in conn", %{conn: conn} do
  #   Process.put(:load_user_data_1, fn nil ->
  #     {:ok, %RestAuth.Authority{token: "abc"}}
  #   end)
  #   conn = RestAuth.Test.authenticate_conn(conn, nil)

  #   assert conn == call(conn, [])
  # end

  # test ""

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
