defmodule PoolRing.Mixfile do
  use Mix.Project

  def project do
    [app: :pool_ring,
     version: "0.1.0",
     elixir: "~> 1.0",
     description: "create a pool based on a hash ring",
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger],
     mod:          {PoolRing, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    []
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     contributors: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/pool_ring"}]
  end
end
