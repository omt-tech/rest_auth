defmodule RestAuth.DummyHandler do
  @moduledoc """
  Sample Handler module showing intended flow and a sample set of
  internal helpers.

  Intention is to be inspiration for your own handler module.
  """

  @behaviour RestAuth.HandlerBehaviour

  @fake_user %{
    name: "Fake User",
    password: "acceptme", # cleartext, do NOT do this, use Comeonin or similar!
    company_id: 33
  }

  require Logger
  alias RestAuth.CacheService

  ################################
  # BEHAVIOUR REQUIRED FUNCTIONS #
  ################################
  def load_user_data(username, raw_password) do
    # This is normally a DB lookup based on the username
    user =
      if username == "fakeuser@example.com" do
        @fake_user
      else
        nil
      end

    case user do
      nil ->
        dummy_check_password()
        {:error, "User not found or wrong password"}
      user ->
        if check_password(user.password, raw_password) do
          Logger.debug "Password accepted, loading user data"
          load_user_data(user)
        else
          Logger.debug "#{user.username}[#{user.name}] did not match password"
          {:error, "User not found or wrong password"}
        end
    end
  end

  def load_user_data(user) do
    metadata = %{
      name: user.name,
      company_id: user.company_id,
    }

    # We put a versioning in the token signature
    # to be able to easily do changes to our token strategy later.
    token_data = %{user_id: user.id, version: 1}
    token = Phoenix.Token.sign(RestAuth.FakeEndpoint, get_salt(), token_data)

    authority =
      %RestAuth.Authority{
        token: token,
        roles: get_roles(user),
        user_id: user.id,
        metadata: metadata,
        anonymous: false
      }
    write_token_to_db(authority)
    CacheService.put_user(authority)
    {:ok, authority}
  end

  def load_user_data_from_token(token) do
    case Phoenix.Token.verify(RestAuth.FakeEndpoint, get_salt(), token) do
      {:ok, %{user_id: user_id, version: 1}} ->
        authority = %RestAuth.Authority{user_id: user_id, token: token}

        case CacheService.get_user(authority) do
          :not_found ->
            case load_token_from_db(authority) do
              nil ->
                {:error, "token invalid"}
              authority ->
                CacheService.put_user(authority)
                {:ok, authority}
            end
          {:ok, authority} ->
            {:ok, authority}
        end
      {:ok, _} ->
        {:error, "token expired"}
      # Error conditions will halt the plug pipeline
      {:error, :expired} ->
        {:error, "token expired"}
      {:error, :invalid} ->
        {:error, "token invalid"}
    end
  end

  def invalidate_token(authority = %RestAuth.Authority{}) do
    delete_token_from_db(authority)
    case CacheService.invalidate_token(authority) do
      {:error, nodes} ->
        Logger.error "Not able to delete tokens on nodes: #{inspect nodes}"
        {:error, "Failed to delete on #{length(nodes)} node(s)"}
      {:ok, _} ->
        :ok
    end
  end

  ####################################
  # OPTIONAL CONFIGURATION CALLBACKS #
  ####################################

  def write_cookie?(), do: false

  def default_required_roles(), do: []

  def anonymous_roles(), do: []

  ######################
  # OPTIONAL CALLBACKS #
  ######################

  # These are not used by the library directly, but are a suggestion on
  # possible further usage in your application

  def can_access_item?(%RestAuth.Authority{user_id: _user_id}, _category, _target_id), do: true

  def invalidate_user_acl(%RestAuth.Authority{user_id: _user_id}), do: :ok

  def invalidate_user(authority = %RestAuth.Authority{}) do
    delete_all_tokens_from_db(authority)
    case CacheService.invalidate_user(authority) do
      {:error, nodes} ->
        Logger.error "Not able to delete tokens on nodes: #{inspect nodes}"
        {:error, "Failed to delete on #{length(nodes)} node(s)"}
      {:ok, _} ->
        :ok
    end
  end

  ###########
  # HELPERS #
  ###########

  defp get_salt() do
    "set_your_own_loooong_salt_here_or_lookup_in_endpoint_config"
  end

  defp check_password(encoded_password, raw_password) do
    # This should normally lean on Comeonin or similar libraries
    encoded_password == raw_password
  end

  defp dummy_check_password() do
    # This should simulate a similar computational cost to check_password
    # to prevent timing attacks
    true
  end

  defp get_roles(_user) do
    #This would normally go fetch in the database
    ["user", "admin"]
  end

  defp write_token_to_db(_authority) do
    # Write the authority to database here.
    # Either attempt to load based on .user_id and .token before
    # writing or put in a unique constraint to make sure you
    # dont end up with multiple identical tokens.
    :ok
  end

  defp load_token_from_db(authority) do
    # Just setting some metadata as a sample here.
    # This function should normally reconstruct the entire
    # Authority from the database.
    %{authority | metadata: %{name: @fake_user.name}}
  end

  defp delete_token_from_db(_authority) do
    # Counterpart to write_token_to_db/1
    :ok
  end

  defp delete_all_tokens_from_db(_authority) do
    :ok
  end
end
