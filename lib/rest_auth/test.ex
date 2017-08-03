defmodule RestAuth.Test do
  @moduledoc """
  Utilities for testing endpoints using `RestAuth`.
  """

  @doc """
  Authenticates connection to bypass the regular header/cookie workflow

  Useful for tests.
  """
  def authenticate_conn(conn, user) do
    handler = conn.private.rest_auth_handler
    {:ok, %RestAuth.Authority{} = authority} = handler.load_user_data(user)
    Plug.Conn.put_private(conn, :rest_auth_authority, authority)
  end

  @doc """
  Allows configuring the test connection.

  Equivalent to calling the `RestAuth.Configure` plug.

  # Example

      # in conn_case.ex

      setup do
        conn = Phoenix.ConnTest.build_conn()
        {:ok, RestAuth.Test.configure(conn, handler: MyApp.Handler)}
      end
  """
  def configure(conn, opts) do
    RestAuth.Configure.call(conn, RestAuth.Configure.init(opts))
  end
end
