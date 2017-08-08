defmodule RestAuth.TestHandler do
  @behaviour RestAuth.Handler

  def load_user_data(username, password) do
    Process.get(:load_user_data_2).(username, password)
  end

  def load_user_data(user) do
    Process.get(:load_user_data_1).(user)
  end

  def load_user_data_from_token(token) do
    Process.get(:load_user_data_from_token).(token)
  end

  def invalidate_token(token) do
    Process.get(:invalidate_token).(token)
  end

  def write_cookie?() do
    Process.get(:write_cookie?)
  end

  def default_required_roles() do
    Process.get(:default_required_roles) || []
  end

  def anonymous_roles() do
    Process.get(:anonymous_roles) || []
  end
end
