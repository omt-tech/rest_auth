defmodule RestAuth.AuthorityTest do
  use ExUnit.Case, async: true

  alias RestAuth.Authority

  describe "authority" do
    test "from binary key map" do
      map = %{"token" => "abc", "unwanted" => "should be dropped"}
      authority = Authority.from_binary_key_map(map)
      assert authority == %Authority{token: "abc"}
      refute Map.get(authority, :unwanted, false)
    end
  end
end
