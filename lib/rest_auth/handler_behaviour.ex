defmodule RestAuth.HandlerBehaviour do
@moduledoc """
  This behavior is a requirement to use RestAUth.
  Please refer to the docs for each function to see how to implement the callbacks.
  """

  @doc """
  This function is used by `RestAuth.Controller` and loads a user from the database.

  Must return a `RestAuth.Authority` struct

  Beware that while `metadata` can be anything it must be serializeable by `Poison` JSON encoder.
  This can be solved by using the standard types like List, Map etc or by implementing the `Poison` protocol.

  Do note that all the data returned here will be embedded in the token, so try to keep it as small as possible.


  The `:error` reason should be a string explaining why the user was not returned.
  Some examples
  * "Wrong username and/or password."
  * "Account is locked"
  * "Account has not been activated yet".
  * "Error connecting to database."

  The supplied controller for RestAuth will json respond with either of the two structures:

  ```
  {
    "data": {
              "token": "g3QAAAACZAAEZGF0YW....udlCH1tpI8oPfIE+BsMcrXj2A=",
              "user_id": 1,
              "roles": ["user", "admin"],
              "metadata":  {"name": "John Doe"}
            }
  }
  ```

  ```
  {
    "error": <your string here>
  }
  ```
  """
  @callback load_user_data(username::String.t, password::String.t) :: {:ok, RestAuth.Authority.t} | {:error, reason::String.t}

  @doc """
  Similar to `load_user_data/2` but simply uses the underlaying user from the database to return the Authority.

  This function is often used for convenience if a user changes his username, name or other data that requires 
  the system to issue a new authority for an already known user.
  """
  @callback load_user_data(user::any) :: {:ok, RestAuth.Authority.t}

  @doc """
  Similar to `load_user_data/1` but should get the user from the token. This function is called on every request
  and should ideally be backed up by `RestAuth.TokenService` or any other caching strategy.
  """
  @callback load_user_data_from_token(token::String.t) :: {:ok, RestAuth.Authority.t} | {:error, reason::String.t}

  
  @doc """
  Looks up if a given authority can access an item in the system.
  Typically does a lookup in the caching layer first then in the database 
  if it is not found there. 
  
  If using the caching layer, remember to write-through
  to the service after loading from the database to decide if access is granted or not.

  Remember to use  `invalidate_user_acl/2` to update the acl cache when granting or denying
  access to things.
  """
  @callback can_access_item?(authority :: RestAuth.Authority.t, category :: String.t, target_id :: any) :: boolean

  @doc """
  Invalidates all user acl based off the `user_id` in the `RestAuth.Authority` struct. 
  Typically used to clear the acl for a user after being granted access to something.
  
  Can be regarded as a companion function
  """
  @callback invalidate_user_acl(authority :: RestAuth.Authority.t) :: :ok | {:error, [Node.t]}

  @doc """
  Invalidates a token.

  Typically this invalidates the token in the cacheservice and deletes it from the database.
  """
  @callback invalidate_token(authority :: RestAuth.Authority.t) :: :ok

  @doc """
  Invalidates a user. This effectively logs out all active sessions across the application

  Typically this invalidates all the tokens in the cacheservice and deletes them from the database.
  """
  @callback invalidate_user(authority :: RestAuth.Authority.t) :: :ok


  
end  