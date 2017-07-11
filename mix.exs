defmodule RestAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rest_auth,
      version: "0.9.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "RestAuth",
      source_url: "https://github.com/omtt/rest_auth"
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
      name: :postgrex,
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Oliver Mulelid-Tynes"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/elixir-ecto/postgrex"}
    ]
  end
end