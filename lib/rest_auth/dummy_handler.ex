defmodule RestAuth.DummyHandler do

  @behaviour RestAuth.HandlerBehaviour

  @fake_user %{
                name: "Fake User",
                password: "acceptme", #cleartext, do NOT do this, use Comeonin or similar!
                company_id: 33
              }

  require Logger
  alias RestAuth.CacheService


  ################################
  # BEHAVIOUR REQUIRED FUNCTIONS #
  ################################
  def load_user_data(username, raw_password) do

    #This is normally a DB lookup based on the username
    if username == "fakeuser@example.com" do
      @fake_user
    else
      nil
    end
    |> case do
      nil ->
        {:error, "User not found or wrong password"}
      user ->
        case check_password(user.password, raw_password) do
          true ->
            Logger.debug "Password accepted, loading user data"
            load_user_data(user)
          false ->
            Logger.debug "#{user.username}[#{user.name}] did not match password"
            {:error, "User not found or wrong password"}
        end
    end
  end

  def load_user_data(user) do
    metadata = %{
      "name" => user.name, 
      "company_id" => user.company_id, 
    }

    # We put a versioning in the token signature
    # to be able to do changes to our token strategy later.
    token_data = %{user_id: user.id, version: 1} 
                 |> Poison.encode!
    token = Phoenix.Token.sign(RestAuth.FakeEndpoint, get_salt(), token_data)

    authority = %RestAuth.Authority{
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

  @doc """
  Decodes a token
  """
  def load_user_data_from_token(token) do
    case Phoenix.Token.verify(RestAuth.FakeEndpoint, get_salt(), token) do
      {:ok, token_data_raw} ->
        Logger.debug "token_data_raw is #{inspect token_data_raw}"
        case Poison.decode(token_data_raw) do
          {:ok, %{"user_id" => user_id, "version" => _}} ->
            authority = %RestAuth.Authority{
                          user_id: user_id,
                          token: token
                        }
            case CacheService.get_user(authority) do
              :not_found ->
                load_token_from_db(authority)
                |> case do
                  nil ->
                    {:error, :invalid}
                  authority ->
                    CacheService.put_user(authority)
                    {:ok, authority}
                end
              {:ok, authority} ->
                {:ok, authority}
            end
          {:ok, _} ->
            {:error, "token expired"}
        end
      #Both error conditions will halt the plug pipeline
      {:error, :expired} ->
        {:error, "token expired"}
      {:error, :invalid} ->
        {:error, "token invalid"}
    end
  end

  

  #Defined with some default values to appease the behaviour gods
  def can_access_item?(%RestAuth.Authority{user_id: _user_id}, _category, _target_id), do: true
  def invalidate_user_acl(%RestAuth.Authority{user_id: _user_id}), do: :ok

  def invalidate_token(authority = %RestAuth.Authority{}) do
    delete_token_from_db(authority)
    CacheService.invalidate_token(authority)
    |> case do
      {:error, nodes} ->
        Logger.error "Not able to delete tokens on nodes: #{inspect nodes}"
        {:error, "Failed to delete on #{length(nodes)} node(s)"}
      _ ->
        :ok
    end
  end

  def invalidate_user(authority = %RestAuth.Authority{}) do
    delete_all_tokens_from_db(authority)
    CacheService.invalidate_user(authority)
    |> case do
      {:error, nodes} ->
        Logger.error "Not able to delete tokens on nodes: #{inspect nodes}"
        {:error, "Failed to delete on #{length(nodes)} node(s)"}
      _ ->
        :ok
    end
  end



  ###########
  # HELPERS #
  ###########

  defp get_salt() do
    "set_your_own_loooong_salt_here"
  end

  
  defp check_password(encoded_password, raw_password) do
    #This should normally lean on Comeonin or similar libraries
    encoded_password == raw_password
  end

  defp get_roles(_user) do
    #This would normally go fetch in the database
    ["user", "admin"]
  end

  #Writes to cache and to db
  defp write_token_to_db(authority) do
    # Write the authority to database here.
    # Either attempt to load based on .user_id and .token before
    # writing or put in a unique constraint to make sure you
    # dont end up with multiple identical tokens.
    authority
  end
  
  defp load_token_from_db(authority) do
    # Just setting some metadata as a sample here.
    # This function should normally reconstruct the entire
    # Authority from the database.
    %{authority | metadata: %{"name" => @fake_user.name}}
  end

  defp delete_token_from_db(%RestAuth.Authority{user_id: _user_id, token: _token}) do
    #Function included as sample
  end

  defp delete_all_tokens_from_db(%RestAuth.Authority{user_id: _user_id}) do
    #Function included as sample
  end

end