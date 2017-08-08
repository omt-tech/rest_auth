defmodule RestAuth.CacheServiceTest do
  # We are only able to set async, since other tests don't use the cache service.
  # If that changes, remember to disable async or suffer from random failures.
  use ExUnit.Case, async: true

  alias RestAuth.CacheService

  setup do
    {:ok, 1} = CacheService.clear()
    :ok
  end

  describe "user" do
    test "get_user returns :not_found without data" do
      authority = %RestAuth.Authority{user_id: 1, token: "abc"}
      assert CacheService.get_user(authority) == :not_found
    end

    test "reads back the user" do
      authority = %RestAuth.Authority{user_id: 1, token: "abc"}
      user = %{authority | metadata: %{"foo" => "bar"}}
      assert CacheService.put_user(user) == {:ok, 1}
      assert CacheService.get_user(authority) == {:ok, user}
    end

    test "invalidate_user clears cache" do
      authority = %RestAuth.Authority{user_id: 1, token: "abc"}
      assert CacheService.put_user(authority) == {:ok, 1}
      assert CacheService.invalidate_user(authority) == {:ok, 1}
      assert CacheService.get_user(authority) == :not_found
    end
  end

  describe "acl" do
    test "can_user_access? returns :not_found without data" do
      authority = %RestAuth.Authority{user_id: 1}
      assert CacheService.can_user_access?(authority, "category", 1) == :not_found
    end

    test "reads back the access" do
      authority = %RestAuth.Authority{user_id: 1}
      assert CacheService.put_user_access(authority, "category", 1, true) == {:ok, 1}
      assert CacheService.can_user_access?(authority, "category", 1)
      assert CacheService.put_user_access(authority, "category", 2, false) == {:ok, 1}
      refute CacheService.can_user_access?(authority, "category", 2)
    end

    test "invalidate_user_access clears cache" do
      authority = %RestAuth.Authority{user_id: 1}
      assert CacheService.put_user_access(authority, "category", 1, true) == {:ok, 1}
      assert CacheService.invalidate_user_access(authority) == {:ok, 1}
      assert CacheService.can_user_access?(authority, "category", 1) == :not_found
    end
  end
end
