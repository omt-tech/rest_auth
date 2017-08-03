defmodule RestAuth.Utility do
  @moduledoc """
  Module is responsible for taking a set of user roles and checking them against required roles on action.
  """
  require Logger

  @doc """
  Returns `true` if one or more of the `required_roles` are in users role, `false` if not
  """
  def is_any_granted?(conn, required_roles) do
    role_intersection(conn, required_roles) in [:all, :some]
  end

  @doc """
    Returns `true` if all of the `required_roles` are in users role, `false` if not
  """
  def is_all_granted?(conn, required_roles) do
    role_intersection(conn, required_roles) == :all
  end

  @doc """
  Returns `true` if none of the `required_roles` are in users role, `false` if not
  """
  def is_none_granted?(conn, required_roles) do
    role_intersection(conn, required_roles) == :none
  end

  @doc """
  Checks if the current user on `conn` is logged in or not
  """
  def is_anonymous?(conn) do
    conn.private.rest_auth_authority.anonymous
  end

  @doc """
  Retrieves current user_id from `conn`.
  Returns `:anonymous` if the user is not authenticated
  """
  def get_current_user_id(conn) do
    conn.private.rest_auth_authority.user_id
  end

  @doc """
  Retrieves roles for current user from `conn`.
  """
  def get_current_user_roles(conn) do
    conn.private.rest_auth_authority.roles
  end

  @doc """
  Gets current metadata saved on `conn`
  """
  def get_current_user_metadata(conn) do
    conn.private.rest_auth_authority.metadata
  end

  @doc """
  Gets current authority struct saved on `conn`
  """
  def get_authority(conn) do
    case conn.private do
      %{rest_auth_authority: %RestAuth.Authority{} = authority} ->
        authority
      _ ->
        raise ArgumentError, "authority struct not found in the conn"
    end
  end

  # Helper method that does a Set intersection between supplied roles and user roles.
  defp role_intersection(conn, required_roles_list) do
    user_roles = MapSet.new(get_current_user_roles(conn))
    required_roles = MapSet.new(required_roles_list)
    required_roles_size = Enum.count(required_roles)
    intersection_count = Enum.count(MapSet.intersection(user_roles, required_roles))

    Logger.debug "Checked user_roles(#{inspect user_roles}) against required_roles(#{inspect required_roles}), intersection_count is (#{intersection_count})"
    case intersection_count do
      ^required_roles_size ->
        :all
      x when x > 0 ->
        :some
      x when x == 0 ->
        :none
    end
  end
end
