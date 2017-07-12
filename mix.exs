defmodule RestAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rest_auth,
      version: "0.9.3",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "RestAuth",
      docs: [main: "RestAuth"],
      source_url: "https://github.com/omttech/rest_auth"
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
      name: :rest_auth,
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Oliver Mulelid-Tynes"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/omttech/rest_auth"}
    ]
  end
end