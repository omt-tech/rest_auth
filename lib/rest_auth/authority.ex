defmodule RestAuth.Authority do

  @moduledoc """
  An authority struct.
  Used to hold information about the current user/authority granted.
  """

  @typedoc """
  Roles defaults to either [] or the specified anonymous roles in your config.
  Anonymous defaults to `true`. Remember to set `anonymous: false` on successful creation
  of `RestAuth.Authority` in your handler!

  """
  @type t :: %RestAuth.Authority{
    token: String.t,
    user_id: Integer.t | any(),
    roles: [String.t],
    metadata: %{String.t => term},
    anonymous: true | false
  }

  @derive {Poison.Encoder, only: [:token, :user_id, :roles, :metadata]}
  defstruct [
    :token, 
    :user_id, 
    {:roles, Application.get_env(:rest_auth, :anonymous_roles, [])},
    {:metadata, %{}},
    {:anonymous, true}
  ]

  @doc """
  Convenience function for transforming a map with binary keys to
  a `RestAuth.Authority` struct. Map keys not in the struct are
  silently dropped.
  """
  def from_binary_key_map(map) do
    Map.take(map, Map.keys(%RestAuth.Authority{}))
    |> Enum.reduce(%RestAuth.Authority{}, fn {k,v}, acc ->
      Map.put(acc, String.to_existing_atom(k), v)
    end)
  end
end
