defmodule RestAuth.CacheService do
  use GenServer

  @genserver_name Application.get_env(:rest_auth, :cache_service_name, RestAuth.TokenService)
  @ets_token_table :rest_auth_token_cache
  @ets_acl_table :rest_auth_acl_cache

  @moduledoc """
  Generic caching service to be used by the user implemented handler module. 
  Has API style meant to be used by the handler and most access should be routed through there. 
  
  The module uses `GenServer.multi_call/4` to flush caches and invalidations out to all
  the nodes. Using this cache without nodes being connected will leave you unable to 
  invalidate acl or kill off user sessions.

  The cache is backed by ets tables and supports read concurrency.
  """

  @doc """
  Looks up a user in the cache based on the authority.
  `user_id` and `token` fields needs to be set for this 
  function to look up anything sensible.
  """
  @spec put_user(authority::RestAuth.Authority.t) :: :not_found | {:ok, RestAuth.Authority.t}
  def get_user(%RestAuth.Authority{user_id: user_id, token: token}) when not is_nil(user_id) and not is_nil(token) do
    ## check cache
    case :ets.match_object(@ets_token_table, {user_id, token, :_}) do
      [] ->
        :not_found
      [{_, _, data}] ->
        {:ok, data}
    end

  end

  @doc """
  Synchronously puts a user in the cache.
  
  The call is syncronous to try to prevent multiple lookups / cache puts across the nodes.
  Returns
    * `{:ok, Integer.t}` If all nodes stored the authority just fine with the int being how many nodes it stored on.
    * `{:error, [Node.t]}` with a list of the bad nodes. Mainly to be used for logging purposes. 
  """
  @spec put_user(authority::RestAuth.Authority.t) :: :ok | {:error, [Node.t]}
  def put_user(auth = %RestAuth.Authority{user_id: user_id, token: token}) when not is_nil(user_id) and not is_nil(token) do
    GenServer.multi_call([node() | Node.list()], @genserver_name, {:put_token, user_id, token, auth}, 5000)
    |> case do
      {nodes, []} ->
        {:ok, length(nodes)}
      {_, nodes} ->
        {:error, nodes}
    end
  end

  @doc """
  Invalidates an authority based on the set `user_id` and `token`.
  Returns
    * `{:ok, Integer.t}` If all nodes invalidated the authority just fine with the int being how many nodes it invalidated on.
    * `{:error, [Node.t]}` with a list of the bad nodes. Mainly to be used for logging purposes. 
  """
  @spec invalidate_token(authority::RestAuth.Authority.t) :: :ok | {:error, [Node.t]}
  def invalidate_token(%RestAuth.Authority{user_id: user_id, token: token}) when not is_nil(user_id) and not is_nil(token) do
    GenServer.multi_call([node() | Node.list()], @genserver_name, {:delete_token, user_id, token}, 5_000)
    |> case do
      {nodes, []} ->
        {:ok, length(nodes)}
      {_, nodes} ->
        {:error, nodes}
    end
  end

  @doc """
  Invalidates all authorities for a given `user_id`.
  
  Returns
    * `{:ok, Integer.t}` If all nodes invalidated the authority just fine with the int being how many nodes it invalidated on.
    * `{:error, [Node.t]}` with a list of the bad nodes. Mainly to be used for logging purposes. 
  """
  @spec invalidate_user(authority::RestAuth.Authority.t) :: :ok | {:error, [Node.t]}
  def invalidate_user(%RestAuth.Authority{user_id: user_id}) when not is_nil(user_id) do
    GenServer.multi_call([node() | Node.list()], @genserver_name, {:delete_all_token, user_id}, 5_000)
    |> case do
      {nodes, []} ->
        {:ok, length(nodes)}
      {_, nodes} ->
        {:error, nodes}
    end
  end

  @doc """
  Looks up if a user can access an item in the system. 
  Returns `:not_found` if there is nothing in the cache and a boolean result if there is.
  """ 
  @spec can_user_access?(authority::RestAuth.Authority.t, category :: String.t, target_id :: any()) :: :not_found | (true | false) 
  def can_user_access?(%RestAuth.Authority{user_id: user_id}, category, target_id)do
    ## check cache
    case :ets.match_object(@ets_acl_table, {user_id, category, target_id, :_ }) do
      [] ->
        :not_found
      [{_, _, data}] ->
        data
    end
  end

  @doc """
  Sets user access for a user_id / category / item id in the caching layer.
  
  Returns
    * `{:ok, Integer.t}` If all nodes stored the access control with int being how many nodes it invalidated on.
    * `{:error, [Node.t]}` with a list of the bad nodes. Mainly to be used for logging purposes. 
  """
  @spec set_user_access(authority::RestAuth.Authority.t, category :: String.t, target_id :: any(), allowed :: boolean) :: :ok | {:error, [Node.t]}
  def set_user_access(%RestAuth.Authority{user_id: user_id}, category, target_id, allowed) do
    GenServer.multi_call([node() | Node.list()], @genserver_name, {:put_acl, user_id, category, target_id, allowed}, 5_000)
    |> case do
      {nodes, []} ->
        {:ok, length(nodes)}
      {_, nodes} ->
        {:error, nodes}
    end
  end

  @doc """
  Invalidates all acls for a given `user_id` in a `RestAuth.Authority`.
  
  Returns
    * `{:ok, Integer.t}` If all nodes invalidated the item acl just fine with the int being how many nodes it invalidated on.
    * `{:error, [Node.t]}` with a list of the bad nodes. Mainly to be used for logging purposes. 
  """
  @spec invalidate_user_acl(authority::RestAuth.Authority.t) :: :ok | {:error, [Node.t]}
  def invalidate_user_acl(%RestAuth.Authority{user_id: user_id}) when not is_nil(user_id) do
    GenServer.multi_call([node() | Node.list()], @genserver_name, {:delete_acl, user_id}, 5_000)
    |> case do
      {nodes, []} ->
        {:ok, length(nodes)}
      {_, nodes} ->
        {:error, nodes}
    end
  end

  ##################
  # GENSERVER CODE #
  ##################

  def init(_args) do
    :ets.new(@ets_token_table, [:named_table, :bag, :protected, read_concurrency: true])
    :ets.new(@ets_acl_table, [:named_table, :bag, :protected, read_concurrency: true])
    {:ok, %{}}
  end

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, [name: @genserver_name])
  end

  def handle_call({:put_token, user_id, token, data}, _from, state) do
    :ets.insert(@ets_token_table, {user_id, token, data})
    {:reply, :ok, state}
  end

  def handle_call({:delete_token, user_id, token}, _from, state) do
    :ets.match_delete(@ets_token_table, {user_id, token, :_})
    {:reply, :ok, state}
  end

  def handle_call({:delete_all_token, user_id}, _from, state) do
    :ets.match_delete(@ets_token_table, {user_id, :_, :_})
    {:reply, :ok, state}
  end

  def handle_call({:put_acl, user_id, category, target_id, allowed}, _from, state) do
    :ets.insert(@ets_acl_table, {user_id, category, target_id, allowed})
    {:reply, :ok, state}
  end

  def handle_call({:delete_acl, user_id}, _from, state) do
    :ets.match_delete(@ets_acl_table, {user_id, :_, :_, :_})
    {:reply, :ok, state}
  end



end
