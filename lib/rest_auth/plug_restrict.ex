defmodule RestAuth.Restrict do
  @moduledoc """
  `RestAuth.Restrict` is used to secure endpoints.

  # Example

      @rest_auth_roles  [
        {:index, ["user"]},
        {:create, ["admin"]},
        {:update, ["admin"]},
        {:show, ["admin"]},
        {:delete, ["admin"]},
        {:ping, :permit_all}
      ]
      plug RestAuth.Restrict @rest_auth_roles

  In this sample usage I have simply listed the roles in an attribute for readability.
  The parameter has to be a keyword list of string lists or atom `:permit_all`.

  """
  require Logger
  import Phoenix.Controller, only: [action_name: 1, json: 2]
  import Plug.Conn

  @doc """
  Required initiation method
  """
  def init(roles) do
    Map.new(roles)
  end

  @doc """
  Checks given roles against current user.
  """
  def call(conn, roles) do
    action = action_name(conn)
    handler = conn.private.rest_auth_handler
    case Map.fetch(roles, action) do
      {:ok, action_roles} ->
        Logger.debug "Securing action #{action} against #{inspect action_roles}"
        check_roles(conn, action_roles)
      :error ->
        Logger.debug "Plug called without roles for #{action}, fetching from handler"
        check_roles(conn, default_required_roles(handler))
    end
  end

  defp check_roles(conn, :permit_all) do
    Logger.debug ":permit_all endpoint, allowing access"
    conn
  end

  defp check_roles(conn, required_roles) do
    cond do
      RestAuth.Utility.is_any_granted?(conn, required_roles) ->
        conn
      RestAuth.Utility.is_anonymous?(conn) ->
        conn
        |> put_status(401)
        |> json(%{"error" => "not authenticated"})
        |> halt()
      true ->
        conn
        |> put_status(403)
        |> json(%{"error" => "you do not have access to this resource"})
        |> halt()
    end
  end

  defp default_required_roles(handler) do
    if function_exported?(handler, :default_required_roles, 0) do
      handler.default_required_roles()
    else
      []
    end
  end
end
