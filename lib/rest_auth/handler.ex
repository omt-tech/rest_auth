defmodule RestAuth.Handler do
  @moduledoc """
  The primary behaviour that drives the use of `RestAuth` in a project.
  """

  @doc """
  Used to load user from a data store.

  Primary use case is in `RestAuth.Controller.login/2`. Must return a
  `RestAuth.Authority` struct with all the relevant user information.

  Beware that while `metadata` can be anything it must be serializeable by
  `Poison` JSON encoder. This can be solved by using the standard types like List,
  Map etc or by implementing the `Poison` protocol.

  Do note that all the data returned here will be embedded in the token,
  so try to keep it as small as possible.

  The `:error` reason should be a string explaining why the user was not returned.
  Some examples

    * "Wrong username and/or password."
    * "Account is locked"
    * "Account has not been activated yet".
    * "Error connecting to database."
  """
  @callback load_user_data(username :: String.t, password :: String.t) ::
            {:ok, RestAuth.Authority.t} | {:error, reason :: String.t}

  @doc """
  Similar to `load_user_data/2`, but uses an already loaded user data and is only
  responsible for converting it into the `RestAuth.Authority` struct.

  This function is often used for convenience if a user changes his username,
  name or other data that requires the system to issue a new authority for an
  already known user. It is also used in `RestAuth.Test.authenticate_conn/2`.
  """
  @callback load_user_data(user::any()) :: {:ok, RestAuth.Authority.t}

  @doc """
  Similar to `load_user_data/1` but constructs the authority struct from
  the token.

  This function is called on every request and should ideally be backed up by
  `RestAuth.CacheService` or any other caching strategy.

  If clientside data is outdated, for example by the handler implementing
  a version field this function can return the authority in a
  `{:client_outdated, RestAuth.Authority.t}` tuple.
  This will make the plug add "x-auth-refresh-token": "true" header to the reply.
  """
  @callback load_user_data_from_token(token::String.t) ::
            {:ok, RestAuth.Authority.t} |
            {:client_outdated, RestAuth.Authority.t} |
            {:error, reason::String.t}

  @doc """
  Verifies the given authority can access an item in the system.

  Typically does a lookup for permissions in the caching layer first,
  then in the database if it is not found there.

  If using the caching layer, remember to write-through to the service after
  loading from the database to decide if access is granted or not.

  Remember to use  `invalidate_user_acl/2` to update the acl cache when
  granting or denying access to things.
  """
  @callback can_access_item?(RestAuth.Authority.t, category :: String.t, target_id :: any()) :: boolean()

  @doc """
  Invalidates all user acl based off the `user_id` in the `RestAuth.Authority`
  struct.

  Typically used to clear the acl for a user after being granted access to
  something with intention of refreshing the acl data on subsequent requests.

  Can be regarded as a companion function
  """
  @callback invalidate_user_acl(authority :: RestAuth.Authority.t) :: :ok | {:error, reason :: String.t}

  @doc """
  Invalidates a token.

  Typically this invalidates the token in the cacheservice and deletes any
  associated data from the database.
  """
  @callback invalidate_token(authority :: RestAuth.Authority.t) :: :ok | {:error, reason :: String.t}

  @doc """
  Invalidates a user.

  This effectively logs out all active sessions across the application

  Typically this invalidates all the tokens in the cacheservice and deletes any
  associated data from the database.
  """
  @callback invalidate_user(authority :: RestAuth.Authority.t) :: :ok | {:error, reason :: String.t}

  @doc """
  A configuration callback to determine, if mechanisms of `RestAuth` should
  be writing into cookies.

  If not implemented, `false` is used.
  """
  @callback write_cookie?() :: boolean
  @optional_callbacks [write_cookie?: 0]

  @doc """
  A configuration callback to provide default required roles.

  If not implemented, `[]` is used.
  """
  @callback default_required_roles() :: [String.t]
  @optional_callbacks [default_required_roles: 0]

  @doc """
  A configuration collback to provide anonymous roles.

  If not implemented, `[]` is used.
  """
  @callback anonymous_roles() :: [String.t]
  @optional_callbacks [anonymous_roles: 0]
end
