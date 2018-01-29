defmodule RestAuth.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :rest_auth,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      description: description(),
      package: package(),
      deps: deps(),
      name: "RestAuth",
      docs: [main: "RestAuth", source_ref: "v#{@version}",
             source_url: "https://github.com/omt-tech/rest_auth"]
    ]
  end

  def application do
    [
      mod: { RestAuth, [] },
      applications: [:logger],
    ]
  end

  defp deps do
    [
      {:phoenix, ">= 1.2.0"},
      {:poison, "~> 2.0 or ~> 3.0", optional: true},
      {:jason, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.14", only: :dev},
    ]
  end

  defp description do
    """
    A comprehensive ACL declarative package.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :rest_auth,
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Oliver Mulelid-Tynes", "Michał Muskała"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/omt-tech/rest_auth"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
