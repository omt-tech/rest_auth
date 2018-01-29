defmodule RestAuth.Authority do
  @moduledoc """
  An authority struct.

  Used to hold information about the current user/authority granted.
  """

  @typedoc """
  Roles defaults to an empty list.
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

  if Code.ensure_loaded?(Poison.Encoder) do
    @derive {Poison.Encoder, only: [:token, :user_id, :roles, :metadata]}
  end

  if Code.ensure_loaded?(Jason.Encoder) do
    @derive {Jason.Encoder, only: [:token, :user_id, :roles, :metadata]}
  end

  defstruct [
    :token,
    :user_id,
    {:roles, []},
    {:metadata, %{}},
    {:anonymous, true}
  ]

  @doc """
  Convenience function for transforming a map with binary keys to
  a `RestAuth.Authority` struct. Map keys not in the struct are
  silently dropped.
  """
  def from_binary_key_map(map) do
    default_authority = %RestAuth.Authority{}
    binary_keys = Map.keys(default_authority)
                  |> Enum.map(&Atom.to_string(&1))
    Map.take(map, binary_keys)
    |> Enum.reduce(default_authority, fn {k,v}, acc ->
      Map.put(acc, String.to_existing_atom(k), v)
    end)
  end
end
