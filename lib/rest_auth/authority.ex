defmodule RestAuth.Authority do
  @typedoc """
  An authority struct.
  Used to hold information about the current user/authority granted.
  """
  @type t :: %RestAuth.Authority{}

  @derive {Poison.Encoder, only: [:token, :user_id, :roles, :metadata]}
  defstruct [
    :token, 
    :user_id, 
    {:roles, Application.get_env(:rest_auth, :anonymous_roles, [])},
    {:metadata, %{}},
    {:anonymous, true}
  ]

  def from_binary_key_map(map) do
    Enum.reduce(map, %RestAuth.Authority{}, fn {k,v}, acc ->
      Map.put(acc, String.to_existing_atom(k), v)
    end)
  end
end
