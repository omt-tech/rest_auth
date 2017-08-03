defmodule RestAuth.CacheService do
  @moduledoc """
  Generic caching service to be used by the user implemented handler module.

  Most functions from the handler, should use the cache service for best
  performance and behaviour.

  The data is cached in ETS tables. The service expects a homogeneous
  node setup where each node has a process called `#{__MODULE__}` that can be
  used for communication. All writes are dispatched through all the nodes using
  `GenServer.multi_call/4`, while reads are dirty from the local ETS table.
  Using this cache without nodes being connected will leave you unable to
  invalidate acl or kill off user sessions.
  """
  use GenServer

  @genserver_name Application.get_env(:rest_auth, :cache_service_name, __MODULE__)
  @ets_token_table Module.concat(@genserver_name, Tokens)
  @ets_acl_table Module.concat(@genserver_name, Acl)

  @type category :: String.t
  @type target_id :: any

  @doc """
  Looks up a user in the cache based on the authority.

  Requires `:user_id` and `:token` fields to be set in the authority struct.
  """
  @spec put_user(RestAuth.Authority.t) :: :not_found | {:ok, RestAuth.Authority.t}
  def get_user(%RestAuth.Authority{user_id: user_id, token: token})
      when not is_nil(user_id) and not is_nil(token) do
    case :ets.match(@ets_token_table, {user_id, token, :"$1"}) do
      [] ->
        :not_found
      [data] ->
        {:ok, data}
    end
  end

  @doc """
  Looks up in the cache if a user can access an item in the system.

  Returns a boolean or `:not_found` if no information is found in the cache.
  """
  @spec can_user_access?(RestAuth.Authority.t, category, target_id) :: :not_found | boolean
  def can_user_access?(%RestAuth.Authority{user_id: user_id}, category, target_id) do
    case :ets.match(@ets_acl_table, {user_id, category, target_id, :"$1"}) do
      [] ->
        :not_found
      [data] ->
        data
    end
  end


  @doc """
  Synchronously puts a user in the cache.

  The call is synchronous to limit concurrent updates from multiple nodes.

  On success returns the count of nodes written to, on failure the list of nodes
  with failed writes.
  """
  @spec put_user(RestAuth.Authority.t) ::
        {:ok, non_neg_integer} | {:error, [Node.t]}
  def put_user(auth = %RestAuth.Authority{user_id: user_id, token: token})
      when not is_nil(user_id) and not is_nil(token) do
    multi_call({:put_token, user_id, token, auth})
  end

  @doc """
  Invalidates an authority based on the set `user_id` and `token`.

  On success returns the count of nodes written to, on failure the list of nodes
  with failed writes.
  """
  @spec invalidate_token(RestAuth.Authority.t) ::
        {:ok, non_neg_integer} | {:error, [Node.t]}
  def invalidate_token(%RestAuth.Authority{user_id: user_id, token: token})
      when not is_nil(user_id) and not is_nil(token) do
    multi_call({:delete_token, user_id, token})
  end

  @doc """
  Invalidates all authorities for a given `user_id`.

  On success returns the count of nodes written to, on failure the list of nodes
  with failed writes.
  """
  @spec invalidate_user(RestAuth.Authority.t) ::
        {:ok, non_neg_integer} | {:error, [Node.t]}
  def invalidate_user(%RestAuth.Authority{user_id: user_id})
      when not is_nil(user_id) do
    multi_call({:delete_all_token, user_id})
  end

  @doc """
  Sets user access for a `user_id`, `category` and `target_id` in the caching layer.

  On success returns the count of nodes written to, on failure the list of nodes
  with failed writes.
  """
  @spec set_user_access(RestAuth.Authority.t, category, target_id, boolean) ::
        {:ok, non_neg_integer} | {:error, [Node.t]}
  def set_user_access(%RestAuth.Authority{user_id: user_id}, category, target_id, allowed?)
      when not is_nil(user_id) and is_boolean(allowed?) do
    multi_call({:put_acl, user_id, category, target_id, allowed?})
  end

  @doc """
  Invalidates all acls for a given `user_id` in a `RestAuth.Authority`.

  On success returns the count of nodes written to, on failure the list of nodes
  with failed writes.
  """
  @spec invalidate_user_acl(RestAuth.Authority.t) ::
        {:ok, non_neg_integer} | {:error, [Node.t]}
  def invalidate_user_acl(%RestAuth.Authority{user_id: user_id})
      when not is_nil(user_id) do
    multi_call({:delete_acl, user_id})
  end

  defp multi_call(msg) do
    nodes = [node() | Node.list()]
    case GenServer.multi_call(nodes, @genserver_name, msg, 5_000) do
      {nodes, []} -> {:ok, length(nodes)}
      {_, failed} -> {:error, failed}
    end
  end

  ##################
  # GENSERVER CODE #
  ##################

  @doc false
  def init(_args) do
    :ets.new(@ets_token_table, [:named_table, :bag, :protected, read_concurrency: true])
    :ets.new(@ets_acl_table, [:named_table, :bag, :protected, read_concurrency: true])
    {:ok, %{}}
  end

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, [name: @genserver_name] ++ opts)
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
