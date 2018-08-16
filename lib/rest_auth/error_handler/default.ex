defmodule RestAuth.ErrorHandler.Default do
  @behaviour RestAuth.ErrorHandler
  @moduledoc """
  Default implementation of `RestAuth.ErrorHandler`.
  """

  alias RestAuth.ErrorHandler

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def cannot_authenticate(conn, reason, from_cookie?) do
    conn
    |> ErrorHandler.clean_cookie(from_cookie?)
    |> put_status(401)
    |> json(%{"error" => reason})
    |> halt()
  end

  def unauthenticated(conn) do
    conn
    |> put_status(401)
    |> json(%{"error" => "not authenticated"})
    |> halt()
  end

  def unauthorized(conn) do
    conn
    |> put_status(403)
    |> json(%{"error" => "you do not have access to this resource"})
    |> halt()
  end
end
