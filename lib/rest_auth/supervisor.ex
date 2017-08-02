defmodule RestAuth.Supervisor do
  use Supervisor
  @moduledoc false

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(RestAuth.CacheService, [])
    ]

    # supervise/2 is imported from Supervisor.Spec
    supervise(children, strategy: :one_for_one)
  end
end
