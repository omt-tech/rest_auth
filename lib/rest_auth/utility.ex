defmodule RestAuth.Utility do
  require Logger

  @moduledoc """
  Module is responsible for taking a set of user roles and checking them against required roles on action.
  """


  @doc """
  Returns `true` if one or more of the `required_roles` are in users role, `false` if not
  """
  def is_any_granted?(conn, required_roles) do
    case role_intersection(conn, required_roles) do
      :all ->
        true
      :some ->
        true
      :none ->
        false
    end
  end

  @doc """
    Returns `true` if all of the `required_roles` are in users role, `false` if not
  """
  def is_all_granted?(conn, required_roles) do
    case role_intersection(conn, required_roles) do
      :all ->
        true
      _ ->
        false
    end
  end

  @doc """
      Returns `true` if none of the `required_roles` are in users role, `false` if not
  """
  def is_none_granted?(conn, required_roles) do
    case role_intersection(conn, required_roles) do
      :none ->
        true
      _ ->
        false
    end
  end


  @doc """
  Checks if the current user on `conn` is logged in or not
  """
  def is_anonymous?(conn) do
    Logger.debug "Checking if user is logged in or not"
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

  def get_authority(conn) do
    conn.private.rest_auth_authority
  end

  #Helper method that does a Set intersection between supplied roles and user roles.
  defp role_intersection(conn, required_roles_list) do
    user_roles = Enum.into (get_current_user_roles(conn)), MapSet.new
    required_roles = Enum.into required_roles_list, MapSet.new
    required_roles_size = Enum.count(required_roles)
    intersection_count = MapSet.intersection(user_roles, required_roles) |> Enum.count

    Logger.debug "Checked user_roles(#{inspect user_roles}) against required_roles(#{inspect required_roles}), intersection_count is (#{intersection_count})"
    case intersection_count do
      x when x == required_roles_size ->
        :all
      x when x > 0 ->
        :some
      x when x == 0 ->
        :none
    end
  end

end
